# CHG-20260810-002：放大 macOS 菜单栏图标

- 状态：Implemented / menu bar smoke pending
- 日期：2026-08-10
- 类型：Bugfix / Brand / macOS

## 背景

`v2.4.0` 实机安装后发现 AltForge Server 菜单栏图标的可见图形偏小。`19x19`/`38x38` asset 尺寸正确，但它们直接缩放了为其他场景保留较大透明边距的 `1024x1024` template master，导致系统菜单栏内的实际标记占比不足。

## 方案

- 保留公共 template master 与 Widget 输出不变。
- 菜单栏两个 scale 在缩放前使用固定、居中的 `780x780` crop，仅去除显示边距，不改变 AltForge 标记几何。
- 保持最终 canvas 为 `19x19` 和 `38x38`，继续使用 macOS template rendering。

## 追踪

- Requirement：`FR-BRAND-001`
- Design：`DES-BRAND-001`
- Verification：`TEST-BRAND-001`

## 复杂度与资源

生成器仅额外处理两个固定尺寸 PNG，时间和空间均为 `O(output pixels)`，使用任务内临时目录并在退出时自动清理，不启动常驻进程。

## 验证与风险

- 品牌资源生成器重复执行后哈希一致；输出仍为 `19x19` 和 `38x38` template assets。
- `2x` 可见 alpha bounds 从 `26x21 @ (6,8)` 放大到 `35x28 @ (2,4)`；`1x` 为 `17x14 @ (1,2)`，均保留安全边距且没有裁切。
- `ruby Scripts/test_repository_contract.rb`、release metadata/version contract 与 `git diff --check` 通过。
- AltServer Debug 通用 macOS 构建通过（`CODE_SIGNING_ALLOWED=NO`）。最终菜单栏外观仍需下一个安装包在真实菜单栏复验。
- 回滚时恢复菜单栏两个输出的直接缩放即可，不涉及数据、协议或迁移。
