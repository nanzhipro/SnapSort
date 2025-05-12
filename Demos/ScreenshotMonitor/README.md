# ScreenshotMonitor

ScreenshotMonitor 是一个用于监控系统截图的 Swift 命令行工具和可重用组件。它可以检测系统截图操作 (Command + Shift + 3/4)，并在截图产生时执行自定义操作。

## 功能特性

- 实时监控系统截图文件夹变化
- 自动检测系统默认截图位置
- 在新截图产生时触发回调
- 可作为组件集成到其他应用中
- 提供命令行工具进行测试和调试

## 组件架构

项目使用组件化设计，遵循高内聚低耦合原则：

- `ScreenshotMonitorProtocol`: 定义监控组件的基本接口
- `DefaultScreenshotMonitor`: 实现上述接口的具体类
- `ScreenshotMonitorError`: 错误类型定义
- `ScreenshotMonitorCLI`: 命令行应用入口

## 编译步骤

### 前提条件

- macOS 12.0 或更高版本
- Swift 5.5 或更高版本
- Xcode 13.0 或更高版本 (可选，仅在 Xcode 中开发时需要)

### 使用 Swift Package Manager 编译

1. 克隆仓库

```bash
git clone <repository-url>
cd ScreenshotMonitor
```

2. 构建库和命令行工具

```bash
swift build
```

3. 运行测试

```bash
swift test
```

4. 安装命令行工具 (可选)

```bash
swift build -c release
cp .build/release/ScreenshotMonitorCLI /usr/local/bin/screenshot-monitor
```

## 使用方法

### 命令行工具

直接运行命令行工具开始监控截图：

```bash
# 基本用法
.build/debug/ScreenshotMonitorCLI

# 使用详细输出模式
.build/debug/ScreenshotMonitorCLI --verbose

# 仅打印截图路径
.build/debug/ScreenshotMonitorCLI --print-only
```

按 `Ctrl+C` 停止运行。

### 作为组件集成到其他应用

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "<repository-url>", from: "1.0.0")
]
```

在代码中使用：

```swift
import ScreenshotMonitor

let monitor = DefaultScreenshotMonitor()
monitor.setScreenshotHandler { url in
    print("检测到新截图: \(url.path)")
    // 处理新截图
}

try monitor.startMonitoring()
```

## 许可证

MIT
