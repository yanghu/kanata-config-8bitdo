# Kanata Config for 8BitDo Retro Mechanical Keyboard

[8bitdo-retro.kbd](./8bitdo-retro.kbd) 将 ZMK 配置（[yanghu/zmk-config-zen-2](https://github.com/yanghu/zmk-config-zen-2/blob/main/config/corneish_zen.keymap)）完整移植到了 **Kanata**，同一份配置文件同时支持 **macOS** 和 **Windows**。

> 已通过 `kanata v1.12.0 --check` 语法校验。

---

## 快速获取

```bash
git clone https://github.com/yanghu/kanata-config-8bitdo.git
cd kanata-config-8bitdo
```

---

## 键位对照速查（8BitDo ANSI TKL）

| 功能 | 8BitDo 按键 | 说明 |
| :--- | :--- | :--- |
| **Home Row Mods** | 按住 `A` = `LCtrl`、`S` = `LShift`、`K` = `LCtrl` | 异手触发 + `require-prior-idle` 防误触（参数对齐 ZMK `lht`/`rht`） |
| **NUMPAD 层** | 按住 `F`（或 `SYMBOL + LWin/Cmd` 锁定） | 右手 `UIO/JKL/M,.` = 7-9/4-6/1-3，空格 = `0`，`RAlt` = `.`，`Y` 退出锁定 |
| **SYMBOL 层** | 按住 **`左 Alt`** | 与 ZMK `symbol_layer` 一致；按住时 `Space` = `0`，`右 Shift` = `FUNC` 层 |
| **NAV 层** | 按住 **`右 Alt`**（或 `SYMBOL + 右 Alt` 锁定） | `H/J/K/L` = 方向键，`Y/U/I` = Home/PgUp/End，`C/V/B` = 静音/音量，再按 `右 Alt` 退出锁定 |
| **FUNC 层** | `左 Alt` + `右 Shift` | `Tab..Bspc` = `F1..F12`；`R` = 热重载配置（`lrld`）；`G` = 切换透传模式 |
| **PSCR 截图层** | 按住 `Enter` | + `Backspace` = `Shift+PrtSc`，+ `'` = `PrtSc` |
| **Sticky Shift** | 轻按 **`右 Shift`**（按住仍为普通 Shift） | 600ms 单次 Shift，对齐 ZMK `&sk LSHIFT` |
| **Caps Tap-Dance** | `CapsLock` | 1 下 = `LShift`，2 下 = `prog_caps_word`（下划线不断开），3 下 = `CapsLock` |
| **Shift + Backspace** | `Shift + Backspace` | 输出 `Delete`（对齐 ZMK `bspc_del`） |
| **物理 Alt / Option** | **`右 Ctrl`** | 因为左右 Alt 用于切层，右 Ctrl 映射为 `LAlt/Option` |
| **Combos** | `M+,` = `Esc`（SYMBOL 层为 `Win/Cmd+L`）<br>`C+V` = `Tab`、`A+S+V` = `Ctrl+Shift+V` | 50ms 触发窗口 |
| **纯透传模式（重要）** | **`ScrollLock`** 键（或 `FUNC + G`） | 一键关闭所有改键/HRM/Combo；Windows 下切回 Zen Corne 或打游戏时按一下，再按一次恢复 |
| **紧急退出 Kanata** | **`LCtrl + Space + Esc`** | Kanata 内置保底快捷键，随时强行退出 |

---

## Windows 安装与运行

1. 从 [Kanata Releases](https://github.com/jtroo/kanata/releases) 下载最新版 Windows 压缩包，推荐使用系统托盘版：
   - **`kanata_windows_gui_winIOv2_x64.exe`**（无须装内核驱动，不冲突反作弊；如需调试日志可用 `kanata_windows_tty_winIOv2_x64.exe`）。
2. 先在终端里验证配置并试跑：
   ```powershell
   .\kanata_windows_tty_winIOv2_x64.exe -c .\8bitdo-retro.kbd
   ```
3. 确认手感没问题后，双击或创建快捷方式运行托盘版（建议勾选**以管理员身份运行**，这样在任务管理器 / 管理员终端窗口里也能生效）：
   ```powershell
   kanata_windows_gui_winIOv2_x64.exe -c "C:\你的路径\kanata-config-8bitdo\8bitdo-retro.kbd"
   ```
   > **提示（多键盘切换）**：Windows 的 `winIOv2` 版无法按物理设备区分键盘。切回 Corneish Zen 或玩网游前，按一下 **`ScrollLock`** 切到 `passthrough` 透传层即可；用回 8BitDo 再按一次 **`ScrollLock`** 恢复。

---

## macOS 安装与运行

1. 安装 Kanata 与 Karabiner 虚拟键盘驱动：
   ```bash
   brew install kanata
   ```
   同时安装 [Karabiner-DriverKit-VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases)（或直接装一次 Karabiner-Elements，只保留后台驱动、退出 Karabiner 主程序即可）。
2. 在 **系统设置 → 隐私与安全性 → 输入监控** 中勾选运行 Kanata 的终端（以及 `kanata` 可执行文件），并允许 Karabiner 系统扩展。
3. **强烈推荐：只接管 8BitDo，不影响 Corneish Zen 和 MacBook 自带键盘**  
   连上 8BitDo 后执行：
   ```bash
   sudo kanata --list
   ```
   找到输出里 8BitDo 的设备名（有线 / 2.4G / 蓝牙模式的名字可能略有不同，可以都填进去），取消 [8bitdo-retro.kbd](./8bitdo-retro.kbd) 中 `macos-dev-names-include` 的注释并填入准确名称。
4. 启动测试：
   ```bash
   sudo kanata -c ./8bitdo-retro.kbd
   ```
   > 如需开机自启，可按 [Kanata macOS 官方文档](https://github.com/jtroo/kanata/discussions/1537) 配置 `LaunchDaemon` plist。

---

## 微调手感

打开 [8bitdo-retro.kbd](./8bitdo-retro.kbd) 顶部的 `defvar` 区域即可按手感调整：
- 误触发修饰键 → 增大 `lht-hold` / `rht-hold`（如从 `180`/`200` 调到 `200`/`220`）或增大 `require-prior-idle`（如 `80` → `120`）。
- 快捷键反应慢 → 适当减小 `lht-hold` / `rht-hold`。
- 保存文件后，按 **`左 Alt + 右 Shift + R`**（`lrld`）即可热重载，不用重启 Kanata。
