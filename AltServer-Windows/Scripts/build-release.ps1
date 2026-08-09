[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [switch]$SkipBootstrap
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed with exit code $LASTEXITCODE."
    }
}

function Invoke-CheckedWithRetry {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [int]$MaximumAttempts = 3
    )

    for ($attempt = 1; $attempt -le $MaximumAttempts; $attempt++) {
        & $Command @Arguments
        if ($LASTEXITCODE -eq 0) {
            return
        }

        if ($attempt -lt $MaximumAttempts) {
            Start-Sleep -Seconds ([Math]::Pow(2, $attempt))
        }
    }

    throw "$Command failed after $MaximumAttempts attempts with exit code $LASTEXITCODE."
}

if (-not $SkipBootstrap) {
    & (Join-Path $PSScriptRoot "bootstrap-dependencies.ps1")
}

$vcpkgRoot = if ($env:VCPKG_ROOT) { $env:VCPKG_ROOT } else { $env:VCPKG_INSTALLATION_ROOT }
if (-not $vcpkgRoot) {
    throw "Set VCPKG_ROOT or VCPKG_INSTALLATION_ROOT before building."
}

$vcpkg = Join-Path $vcpkgRoot "vcpkg.exe"
if (-not (Test-Path $vcpkg)) {
    throw "vcpkg.exe was not found at $vcpkg"
}

$programFilesX86 = [Environment]::GetFolderPath("ProgramFilesX86")
$vswhere = Join-Path $programFilesX86 "Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
    throw "Visual Studio Installer could not be located."
}

$msbuild = (& $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe" | Select-Object -First 1)
if (-not $msbuild) {
    throw "MSBuild could not be located."
}

$installedDirectory = Join-Path $root "vcpkg_installed"
Invoke-CheckedWithRetry -Command $vcpkg -Arguments @(
    "install",
    "--triplet", "x86-windows",
    "--x-manifest-root=$root",
    "--x-install-root=$installedDirectory"
)

$mdnsRoot = Join-Path $root "Dependencies\mDNSResponder"
$mdnsProject = Join-Path $mdnsRoot "mDNSWindows\DLL\dnssd.vcxproj"
Invoke-Checked -Command $msbuild -Arguments @(
    $mdnsProject,
    "/m",
    "/p:Configuration=Release",
    "/p:Platform=Win32"
)

$solution = Join-Path $root "AltServer.sln"
Invoke-Checked -Command $msbuild -Arguments @(
    $solution,
    "/m",
    "/t:AltServer",
    "/p:Configuration=Release",
    "/p:Platform=x86",
    "/p:PlatformToolset=v143",
    "/p:VcpkgInstalledDir=$installedDirectory\",
    "/p:MDNSResponderDir=$mdnsRoot\"
)

& (Join-Path $PSScriptRoot "package-release.ps1") -OutputDirectory $OutputDirectory
