# YouTube for macOS (Native Cinema & Shorts)

原生轻量、沉浸无界的 macOS 专属 YouTube 客户端。基于 Swift 与系统级 WebKit 原生架构打造，杜绝 Electron 臃肿资源占用，带来丝滑纯净的流媒体观影体验。

---

## ✨ 核心亮点 (Key Features)

- 🚀 **双引擎动态切换 (Dual-Engine)**：
  - **16:9 横屏影院模式 (Cinema Mode)**：纯净无黑边，自动拦截贴片广告，全屏沉浸播放，支持画中画 (PiP) 与连播。
  - **9:16 竖屏短视频模式 (FikFap Engine)**：智能识别 YouTube Shorts，原生窗口平滑过渡至 9:16，无缝全屏填充，短视频结束自动平滑切换至下一条。
- ⚡️ **超轻量与极致性能**：
  - 基于原生 Swift + WebKit，无 Electron 运行时，极低 CPU 与内存占用。
  - 接入硬件加速与 Metal 渲染引擎，杜绝卡顿与掉帧。
- 🛡️ **纯净防打扰**：
  - 自动跳过视频贴片广告与横幅干扰。
  - 智能去除多余滚动条与空白留白。
- ⌨️ **沉浸式快捷键**：
  - `Space`：播放 / 暂停
  - `↓` / `J`：下一个视频
  - `↑` / `K`：上一个视频
  - `M`：静音 / 取消静音
  - `P`：画中画模式 (Picture-in-Picture)
  - `T`：窗口置顶 / 取消置顶
  - `[` / `]`：倍速调节 (0.75x ~ 2.0x)
  - `R`：刷新当前流
- 🔋 **防休眠与系统优化**：
  - 播放视频期间自动阻止屏幕休眠 (IOPMAssertion)。
  - 网络自动重连与防 App Nap 保护。

---

## 🛠️ 构建与运行 (Build & Run)

### 环境要求
- macOS 12.0 (Monterey) 或更高版本
- Apple Silicon (M1/M2/M3/M4) 或 Intel 架构
- Xcode Command Line Tools (`xcode-select --install`)

### 一键构建
```bash
git clone https://github.com/mircostone/YouTubeApp.git
cd YouTubeApp
./build.sh
```

构建完成后，`YouTube.app` 将生成在项目根目录中，双击即可直接运行，或拖入 `/Applications`。

---

## 📄 开源许可 (License)

本项目采用 MIT 许可证，详情请参阅 [LICENSE](LICENSE)。
