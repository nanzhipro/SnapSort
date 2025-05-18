# FileOrganizer 组件使用文档

`FileOrganizer` 是一个用于管理和组织截图文件的组件，支持将截图移动到用户定义的分类目录，自动处理文件名冲突，并提供详细的错误处理和日志记录。

## 组件结构

- `FileOrganizerProtocol.swift`: 定义组件的核心接口
- `FileOrganizer.swift`: 组件的具体实现
- `FileOrganizerError.swift`: 定义组件可能抛出的错误
- `FileSystemLogger.swift`: 提供文件系统操作的日志记录功能

## 基本用法

### 初始化 FileOrganizer

```swift
// 使用 URL 初始化
let baseDirectory = URL(fileURLWithPath: "/path/to/screenshots", isDirectory: true)
let organizer = try FileOrganizer(baseDirectory: baseDirectory)

// 或使用路径字符串初始化
let organizer = try FileOrganizer(baseDirectoryPath: "/path/to/screenshots")
```

### 移动截图文件

```swift
// 使用 URL 移动文件
let sourceURL = URL(fileURLWithPath: "/path/to/screenshot.png")
let newURL = try organizer.moveScreenshot(from: sourceURL, to: "Work")

// 或使用路径字符串移动文件
let sourcePath = "/path/to/screenshot.png"
let newPath = try organizer.moveScreenshot(from: sourcePath, to: "Work")
```

## 错误处理

`FileOrganizer` 可能抛出以下错误：

- `sourceFileNotFound`: 源文件不存在
- `directoryCreationFailed`: 创建目录失败
- `fileMoveFailed`: 移动文件失败
- `invalidFilePath`: 无效的文件路径
- `fileAlreadyExists`: 文件已存在且无法覆盖

建议使用 `try-catch` 块处理这些错误：

```swift
do {
    let newPath = try organizer.moveScreenshot(from: sourcePath, to: category)
    print("文件已移动到: \(newPath)")
} catch let error as FileOrganizerError {
    // 处理特定错误
    switch error {
    case .sourceFileNotFound(let path):
        print("源文件不存在: \(path)")
    case .fileMoveFailed(let source, let destination, let underlyingError):
        print("移动文件失败: 从 \(source) 到 \(destination)")
        print("错误: \(underlyingError.localizedDescription)")
    default:
        print("发生错误: \(error.localizedDescription)")
    }
} catch {
    // 处理其他错误
    print("未知错误: \(error.localizedDescription)")
}
```

## 日志记录

`FileOrganizer` 内部使用 `FileSystemLogger` 记录操作日志，包括调试、信息和错误级别的日志。所有日志都会通过 `OSLog` 系统集成到系统日志中，可以在 Console.app 中查看。

## 高级用例

### 自动创建分类目录

`FileOrganizer` 会自动创建不存在的分类目录，无需手动创建。

### 文件名冲突处理

当目标目录中已存在同名文件时，`FileOrganizer` 会自动添加数字后缀（如 `screenshot_1.png`）以避免冲突。

### 自定义基础目录

可以根据需要自定义基础目录，例如：

```swift
// 使用用户的图片目录
let picturesDir = try FileManager.default.url(
    for: .picturesDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: false
)
let screenshotsDir = picturesDir.appendingPathComponent("Screenshots")
let organizer = try FileOrganizer(baseDirectory: screenshotsDir)
```

## 性能考虑

- 文件移动操作是原子性的，确保数据安全
- 目录创建和文件名冲突解决有适当的错误处理
- 大批量文件处理时，建议考虑异步操作
