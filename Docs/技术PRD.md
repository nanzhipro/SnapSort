# SnapSort macOS 技术实现方案

## 1. 产品概述

SnapSort 是一款专为 macOS 用户打造的智能截图管理应用。它巧妙利用 macOS 系统底层的 `NSMetadataQuery` 机制，通过监测 `kMDItemScreenCaptureType` 元数据变更，实现对新增系统截图的即时自动捕捉。一旦捕获截图，SnapSort 会立即进行精准的 OCR 文本识别。随后，强大的 AI 引擎会以识别出的文本内容为核心依据，并深度结合您预设的分类目录及动态维护的关键词列表（作为上下文传递给 AI），智能地将每一张截图自动归档至最匹配的用户自定义文件夹中。

SnapSort 致力于为每日面对海量截图的专业人士——包括但不限于开发者、设计师、研究员及产品经理——解决截图管理混乱、关键信息难以检索的痛点。它能帮助您从繁杂的默认截图中解放出来，迅速定位并重新利用那些曾经认为有价值的视觉片段，从而真正释放每一张截图的潜在效能，显著提升您的工作效率和信息组织能力。我们高度重视用户数据隐私，SnapSort 支持纯本地化的 AI 模型处理（例如通过 Ollama 运行本地模型），同时也提供连接到如 DeepSeek 等云端 AI 服务的灵活性，旨在为您提供一个无缝集成、高效智能且充分个性化的截图管理新体验。

## 1.1 设计哲学

### 1. 智能无感，效率至上 (Effortless Intelligence, Peak Efficiency)

- **核心**：通过高度智能化的自动处理，最大限度减少用户的手动干预，让截图的整理和分类过程近乎"自动驾驶"。
- **体现**：如利用 `NSMetadataQuery` 实现无打扰的后台监测；AI 自动精准分类。目标是让用户在享受整洁有序的截图管理的同时，几乎感觉不到应用的存在，只在需要时提供即时价值。

### 2. 原生集成，体验无缝 (Native Integration, Seamless Experience)

- **核心**：深度融入 macOS 生态，提供与系统一致的流畅体验。
- **体现**：使用 `NSMetadataQuery` 而非侵入式方法；遵循苹果的设计规范；确保低资源占用，不干扰用户主要工作流程。

### 3. 用户赋能，掌控由心 (User Empowerment, Personalized Control)

- **核心**：虽然强调自动化，但最终的控制权和个性化定义始终在用户手中。AI 是助手，用户是决策者。
- **体现**：用户可以完全自定义分类目录、管理关键词列表；用户可以选择 AI 模型（本地/云端）以平衡隐私、成本和效果。应用应能学习和适应用户的偏好。

### 4. 隐私为本，安全优先 (Privacy by Design, Security First)

- **核心**：在数据处理的每一个环节都将用户隐私和数据安全放在首位。
- **体现**：优先推荐和支持本地化处理方案；明确告知用户数据的使用方式；不收集非必要信息；如果使用云端服务，确保数据传输和处理的安全性。

## 2. 技术方案

## 概述

SnapSort 是一款专为 macOS 用户设计的截图管理工具，旨在通过实时监控、OCR 文本识别、AI 智能分类和文件管理，自动化处理截图，同时确保隐私保护和无缝的用户体验。本文档从技术实现和代码编写的角度，基于产品需求文档（PRD），提供完整的 macOS 技术方案，遵循 Apple 设计规范和最佳实践。

## 技术架构

- **编程语言**：Swift，Apple 推荐的 macOS 开发语言，集成性强。
- **UI 框架**：SwiftUI/MenuBarExtra
- **数据库**：Core Data 存储截图元数据，UserDefaults 存储用户设置，简单高效。
- **OCR**：Apple Vision 框架，支持多语言文本识别，优化性能。
- **AI 分类**：本地关键词匹配和可选的 DeepSeek API 云端分类，灵活满足用户需求。
- **文件管理**：FileManager 处理文件移动和目录创建，稳定可靠。
- **截图监控**：NSMetadataQuery 实时检测新截图，轻量高效。

## 核心组件与实现细节

以下是 SnapSort 的核心组件及其技术实现方式，涵盖 PRD 的所有功能需求。

### 1. 截图监控（ScreenshotMonitor）

**功能**：实时检测系统默认截图行为（Command + Shift + 3/4），后台运行，自动启动。

**实现**：

- 使用 `NSMetadataQuery` 监控截图目录，谓词为 `kMDItemIsScreenCapture == 1`，确保只捕获系统截图。
- 通过运行 `defaults read com.apple.screencapture location` 获取截图保存目录，处理默认桌面或其他用户定义路径。
- 使用 `NSString.expandingTildeInPath` 扩展路径中的 `~`。
- 监听查询通知，处理新截图事件，响应时间控制在 3 秒内。
- 使用 `LaunchAtLogin` 实现开机自动启动，用户可通过设置启用/禁用。这是一个github的开源项目，地址是：<https://github.com/sindresorhus/LaunchAtLogin-Modern。>

- 示例代码见： Demos/ScreenshotMonitor/Sources/ScreenshotMonitor/ScreenshotMonitor.swift

**最佳实践**：

- 异步处理查询通知，避免阻塞主线程。
- 定期检查截图目录变化，更新查询范围。
- 限制并发处理，防止多张截图同时触发导致性能问题。

**参考文档**：
NSMetadataQuery：<https://developer.apple.com/documentation/foundation/nsmetadataquery>

### 2. OCR 文本识别（OCRProcessor）

**功能**：支持中文、日文和英文的高精度文本识别，资源消耗低，识别时间小于 5 秒/张。

**实现**：

- 使用 Vision 框架的 `VNRecognizeTextRequest`，支持多语言（包括中文简体/繁体、日文等）。
- 通过 `supportedRecognitionLanguages(for:revision:)` 获取支持的语言列表，供用户在设置中选择。
- 使用 `VNImageRequestHandler` 处理截图图像，异步执行以优化性能。
- 配置 `recognitionLevel` 为 `.accurate`，确保高精度。

**最佳实践**：

- 支持用户自定义语言，动态调整 `recognitionLanguages`。
- 处理 OCR 失败情况，标记截图以供手动审查。
- 使用 DispatchQueue 异步处理，确保主线程流畅。
- 使用并继续完善现有组件： QuestOCR模块： SnapSort/Infrastructure/Services/QuestOCR

<!-- ### 3. 敏感信息检测（SensitiveInfoDetector）

**功能**：标记包含敏感信息（如密码、信用卡号）的截图，支持用户自定义规则。

**实现**：

- 使用正则表达式匹配常见敏感数据模式（如信用卡号、邮箱地址）。
- 允许用户在设置中添加自定义正则表达式或关键词。
- 检测到敏感信息后，标记截图并可选移动到"敏感"目录。

**正则表达式示例**：

| 数据类型       | 正则表达式                              |
|----------------|-----------------------------------------|
| 信用卡号       | `\b(?:\d[ -]*?){13,16}\b`              |
| 邮箱地址       | `\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b` |
| 电话号码       | `\b\d{3}-\d{3}-\d{4}\b`                |

**代码示例**：

```swift
func detectSensitiveInfo(in text: String, patterns: [String]) -> Bool {
    for pattern in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: text.utf16.count)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                return true
            }
        }
    }
    return false
}
```

**最佳实践**：

- 提供默认敏感数据模式，允许用户测试自定义模式。
- 记录检测结果，供用户审查。
- 确保正则表达式性能优化，避免复杂模式导致延迟。 -->

### 4. AI 智能分类（AIClassifier）

**功能**：基于 OCR 识别后的文本结果进行智能分类，支持用户定义类别和关键词列表，集成 DeepSeek API，低资源占用。

**实现**：

- **云端分类**：
  - 使用 DeepSeek API（兼容 OpenAI 格式，基 URL 为 `https://api.deepseek.com/v1`）。
  - 构造提示，包含 OCR 文本和类别列表，调用 `deepseek-chat` 模型。
  - 解析响应，获取分类结果，若为新类别，提示用户确认。
- 未分类截图存储在"未分类"目录，供用户后续处理。
- **DeepSeek API接口文档**：
本地： Docs/DSAPI.md
URL：<https://api-docs.deepseek.com/zh-cn/>
- **DeepSeak JSON Output**:
本地：Docs/DeepSeekJSONOutput.md
URL：<https://api-docs.deepseek.com/zh-cn/guides/json_mode>

**JSON Outout示例代码**：

```python
import json
from openai import OpenAI

client = OpenAI(
    api_key="<your api key>",
    base_url="https://api.deepseek.com",
)

system_prompt = """
The user will provide some exam text. Please parse the "question" and "answer" and output them in JSON format. 

EXAMPLE INPUT: 
Which is the highest mountain in the world? Mount Everest.

EXAMPLE JSON OUTPUT:
{
    "question": "Which is the highest mountain in the world?",
    "answer": "Mount Everest"
}
"""

user_prompt = "Which is the longest river in the world? The Nile River."

messages = [{"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}]

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=messages,
    response_format={
        'type': 'json_object'
    }
)

print(json.loads(response.choices[0].message.content))
```

**最佳实践**：

- 提供云端选项，明确告知用户云端数据传输。
- 使用 Keychain 存储 API 密钥，确保安全。
- 处理 API 失败情况，降级到本地分类或标记为未分类。

### 5. 文件管理（FileOrganizer）

**功能**：将截图移动到用户定义的分类目录，支持自定义目录结构，自动创建目录。

**实现**：

- 使用 `FileManager` 移动截图到基于类别的目录（如 `~/Screenshots/Classified/Work`）。
- 处理文件名冲突，添加时间戳或序号。
- 自动创建不存在的目录，使用 `createDirectory(at:withIntermediateDirectories:)`。

**代码示例**：

```swift
func moveScreenshot(from sourceURL: URL, to category: String, baseDirectory: String) throws {
    let fileManager = FileManager.default
    let categoryDir = (baseDirectory as NSString).appendingPathComponent(category)
    try fileManager.createDirectory(atPath: categoryDir, withIntermediateDirectories: true)
    let destinationURL = URL(fileURLWithPath: categoryDir).appendingPathComponent(sourceURL.lastPathComponent)
    var finalURL = destinationURL
    var counter = 1
    while fileManager.fileExists(atPath: finalURL.path) {
        let newName = "\(sourceURL.deletingPathExtension().lastPathComponent)_\(counter).\(sourceURL.pathExtension)"
        finalURL = URL(fileURLWithPath: categoryDir).appendingPathComponent(newName)
        counter += 1
    }
    try fileManager.moveItem(at: sourceURL, to: finalURL)
}
```

**最佳实践**：

- 确保文件移动原子性，避免数据丢失。
- 提供用户可配置的基目录设置。
- 日志记录文件操作，便于调试。

### 6. 数据库管理（DatabaseManager）

**功能**：存储截图元数据，支持基于 OCR 结果的文本搜索。

**实现**：

- 使用 SQLite 数据库存储截图元数据，表结构包括：
  - 表名：`Screenshots`
  - 字段：`imageFilePath`（TEXT, 主键）、`classification`（TEXT）、`fullText`（TEXT）
- 使用 Swift 标准库中的 `SQLite.swift` 轻量级封装，简化数据库操作
- 提供搜索功能，查询 `fullText` 匹配用户输入的关键词
- 使用 `NSWorkspace` 打开 Finder，选中搜索结果文件
- SQLite.swift(A type-safe, Swift-language layer over SQLite3): <https://github.com/stephencelis/SQLite.swift>
- SQLite.swift文档： Docs/SQLiteSwiftDoc.md
<https://raw.githubusercontent.com/stephencelis/SQLite.swift/refs/heads/master/Documentation/Index.md>

**最佳实践**：

- 使用 SQL 索引优化文本搜索性能
- 实现数据库文件的自动备份机制，防止数据损坏
- 使用事务处理批量操作，提高数据库写入效率
- 错误处理机制确保数据库操作失败不会崩溃应用
- 实现定期清理无效记录（如已删除的文件）的维护例程

### 7. 用户界面（SettingsManager & UI）

**功能**：通过菜单栏图标访问设置，管理类别、目录、语言等，无独立截图浏览界面，依赖 Finder。

**实现**：

- **菜单栏**：使用SwiftUI `menubarextra` ,且`.menuBarExtraStyle(.menu)`。并提供：设置和退出两个菜单选项
- **设置窗口**：使用 SwiftUI Setting 构建，包含以下 SettingLink 部分：
  - 通用：自动启动、通知偏好。
  - 类别：添加/编辑/删除类别及其关键词。
  - 目录：设置分类基础目录。
  - 隐私：定义敏感信息模式。
  - AI Key：选择本地/云端，输入 API 密钥。
- 使用 `@AppStorage` 绑定 UserDefaults 设置，动态更新 UI。

参考文档：

- SwiftUI SettingLink： <https://developer.apple.com/documentation/swiftui/settingslink>
- SwiftUI Setting： <https://developer.apple.com/documentation/swiftui/settings>
- SwiftUI menubarextra： <https://developer.apple.com/documentation/swiftui/menubarextra>
.menuBarExtraStyle(.menu)
- 详见： Docs/设置页面.md

**最佳实践**：

- 遵循 Apple 人机交互指南，确保界面简洁直观。
- 提供即时反馈，如保存设置时的提示。
- 支持国际化，预留多语言扩展。

### 8. 通知管理（NotificationManager）

**功能**：通知用户分类完成、未分类截图或敏感信息警告，集成 macOS 通知系统。

**实现**：

- 使用 `UNUserNotificationCenter` 发送通知，请求用户授权。
- 定义通知类别，如"未分类"和"敏感信息"，支持操作（如打开设置）。
- 异步调度通知，避免影响主线程。

**代码示例**：

```swift
func sendNotification(title: String, body: String, category: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.categoryIdentifier = category
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
}
```

**最佳实践**：

- 限制通知频率，避免打扰用户。
- 提供关闭通知的选项。
- 确保通知内容简洁，包含必要操作。

## 性能与优化

- **CPU 和内存**：异步处理截图，限制并发任务，目标 CPU 占用 <5%，内存 <200MB。
- **响应时间**：截图检测 <3 秒，OCR <5 秒，通过 Instruments 监控性能。
- **批量处理**：处理快速连续截图，批量更新数据库和文件移动。
- **日志记录**：记录关键操作，便于调试和性能分析。

## 安全与隐私

- **本地处理**：默认所有处理（OCR、分类、敏感信息检测）在本地完成，无数据上传。
- **云端选项**：云端分类需用户明确同意，OCR 文本通过 HTTPS 传输至 DeepSeek API。
- **密钥安全**：API 密钥存储在 Keychain，使用 Security 框架访问。
- **权限管理**：仅请求必要权限（如桌面访问），提供清晰的权限说明。
- **隐私声明**：在设置中提供隐私政策，说明数据使用和保护措施。

## 兼容性

- **系统版本**：支持 macOS 15 及以上版本。
- **硬件**：构建通用二进制文件，兼容 Apple Silicon 和 Intel 处理器。
- **测试**：在不同 macOS 版本和硬件上测试，确保稳定性。

## 遵循 Apple 设计规范

- **人机交互指南**：使用标准 UI 元素，保持简洁和直观。
- **隐私设计**：透明的数据使用政策，优先本地处理。
- **安全编码**：遵循 Apple 的安全编码指南，防止漏洞。
- **性能优化**：确保应用不影响系统睡眠或电池续航。

## 自我审查与可行性

- **正确性**：方案基于 Apple 原生框架，参考官方文档，确保实现准确。
- **可行性**：所有组件（如 NSMetadataQuery、Vision、DeepSeek API）均经过验证，适用于 macOS 环境。
- **先进性**：使用 SwiftUI 和 Vision 等现代技术，保持技术前瞻性。
- **边缘情况**：
  - 多张截图：批量处理，限制并发。
  - 截图格式：Vision 支持 PNG、JPEG 等常见格式。
  - API 失败：给出失败反馈。
  - 目录冲突：自动处理文件名冲突，增加编号。
- **测试计划**：
  - 单元测试：分类逻辑、文件移动。
  - 集成测试：完整工作流程。
  - 性能测试：使用 Instruments 验证 CPU 和内存占用。

## 关键引用

- [NSMetadataQuery 官方文档](https://developer.apple.com/documentation/foundation/nsmetadataquery)
- [Vision 框架官方文档](https://developer.apple.com/documentation/vision)
- [Core Data 官方文档](https://developer.apple.com/documentation/coredata)
- [SwiftUI 官方文档](https://developer.apple.com/documentation/swiftui)
- [AppKit 官方文档](https://developer.apple.com/documentation/appkit)
- [Security 框架官方文档](https://developer.apple.com/documentation/security)
- [Apple 人机交互指南](https://developer.apple.com/design/human-interface-guidelines/)
- [DeepSeek API 官方文档](https://api-docs.deepseek.com/)
- ollama文档： <https://github.com/ollama/ollama/blob/main/docs/api.md>
