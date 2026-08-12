#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LDID_DIR="$ROOT_DIR/Dependencies/AltSign/Dependencies/ldid"
OPENSSL_INCLUDE_DIR="$ROOT_DIR/Dependencies/AltSign/Dependencies/OpenSSL/macosx/include"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/altforge-ldid-architecture.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

cat > "$WORK_DIR/main.c" <<'EOF'
int main(void)
{
    return 0;
}
EOF

cat > "$WORK_DIR/test.cpp" <<'EOF'
#include <openssl/objects.h>

#define LDID_NOSMIME
#define LDID_NOPLIST
#define LDID_NOTOOLS

#include "ldid.cpp"

struct TestProgress : ldid::Progress
{
    mutable std::vector<std::string> architectures;

    void operator()(const std::string &value) const override
    {
        architectures.push_back(value);
    }

    void operator()(double) const override
    {
    }
};

int main(int argc, char **argv)
{
    if (argc != 3)
    {
        return 2;
    }

    std::ifstream input(argv[1], std::ios::binary);
    std::string binary((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
    std::stringbuf output;
    TestProgress progress;
    ldid::Slots slots;

    try
    {
        ldid::Sign(binary.data(), binary.size(), output, "com.altforge.architecture-test", "", false, "", "", slots, 0, false, progress);
    }
    catch (const std::runtime_error &error)
    {
        if (std::string(argv[2]) == "unsupported" && std::string(error.what()).find("unsupported CPU type") != std::string::npos)
        {
            return 0;
        }

        throw;
    }

    if (std::string(argv[2]) != "arm64_32")
    {
        return 3;
    }

    if (progress.architectures.size() != 1 || progress.architectures.front() != "arm64_32")
    {
        return 4;
    }

    return output.str().empty() ? 5 : 0;
}
EOF

xcrun --sdk watchos clang \
    -target arm64_32-apple-watchos7.0 \
    -Wl,-adhoc_codesign \
    -o "$WORK_DIR/arm64_32-watch" \
    "$WORK_DIR/main.c"

xcrun clang \
    -w \
    -std=gnu89 \
    -c \
    -o "$WORK_DIR/lookup2.o" \
    "$LDID_DIR/lookup2.c"

xcrun clang++ \
    -w \
    -std=c++14 \
    -I"$LDID_DIR" \
    -I"$OPENSSL_INCLUDE_DIR" \
    -framework Security \
    -framework CoreFoundation \
    -o "$WORK_DIR/test" \
    "$WORK_DIR/test.cpp" \
    "$WORK_DIR/lookup2.o"

"$WORK_DIR/test" "$WORK_DIR/arm64_32-watch" arm64_32

cp "$WORK_DIR/arm64_32-watch" "$WORK_DIR/unsupported-watch"
ruby -e '
  path = ARGV.fetch(0)
  bytes = File.binread(path)
  bytes[4, 4] = [0x63].pack("V")
  File.binwrite(path, bytes)
' "$WORK_DIR/unsupported-watch"
"$WORK_DIR/test" "$WORK_DIR/unsupported-watch" unsupported

echo "ldid architecture compatibility: PASS"
