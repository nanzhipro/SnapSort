# SnapSort 技术文档

## 设计哲学

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

## 核心功能详解

### 截图监测

- 监测系统默认截图行为（Command + Shift + 3（屏幕截图）或 Command + Shift + 4（区域截图））
- 实时检测新生成的截图文件（基于 `kMDItemScreenCaptureType` 元数据）
- 后台运行，无需用户主动打开应用
- 系统启动时自动运行

### OCR 文本识别

- 支持中文、日文、英文三国语言的识别
- 架构设计支持快速扩展其他语言
- 高精确度的文本识别
- 低资源消耗的识别实现

### AI 智能分类

- 基于 OCR 识别结果，对截图内容进行智能分类
- 利用历史分类和用户自定义分类目录及关键词作为上下文辅助 AI 决策
- 当发现无法匹配现有分类时，提示用户是否创建新分类
- 支持连接 DeepSeek API 或运行本地 AI 模型进行智能分类处理，兼顾性能与隐私

### 文件管理

- 将原始截图文件移动（非复制）到对应的分类目录
- 支持自定义分类目录结构
- 自动创建不存在的分类目录

### 隐私保护

- 对包含敏感信息的截图进行标记与隔离建议
- 支持用户自定义敏感信息类型
- 内置常见敏感信息识别规则（如密码、信用卡号、个人身份信息等）

### 搜索功能

- 基于 OCR 识别结果提供文本搜索能力
- 支持关键词和自然语言查询

## 技术规格

### 性能指标

- 低 CPU 占用率（<5% 平均）
- 低内存占用（<200MB）
- 快速响应截图事件（<3 秒）
- OCR 识别速度快（<5 秒/张图）

### 兼容性

- 支持 macOS 15 及以上版本
- 适配 Apple Silicon 和 Intel 处理器

### 安全和隐私

- 所有处理在本地完成，不上传用户数据
- 申请最小必要的系统权限
- 符合 Apple 隐私设计准则

## 技术实现

### 核心技术栈

- **框架**：SwiftUI + AppKit
- **截图监测**：NSMetadataQuery + kMDItemScreenCaptureType
- **OCR 引擎**：Vision Framework
- **AI 集成**：支持本地模型（Ollama）和云端服务（DeepSeek API）
- **数据存储**：Core Data / SQLite
- **文件管理**：FileManager + NSWorkspace

### 架构设计

```
SnapSort/
├── Core/
│   ├── ScreenshotMonitor.swift      # 截图监测核心
│   ├── OCREngine.swift              # OCR 识别引擎
│   ├── AIClassifier.swift           # AI 分类器
│   └── FileManager.swift            # 文件管理器
├── Models/
│   ├── Screenshot.swift             # 截图数据模型
│   ├── Category.swift               # 分类模型
│   └── Settings.swift               # 设置模型
├── ViewModels/
│   ├── MainViewModel.swift          # 主视图模型
│   ├── SettingsViewModel.swift      # 设置视图模型
│   └── SearchViewModel.swift        # 搜索视图模型
├── Views/
│   ├── MainView.swift               # 主界面
│   ├── SettingsView.swift           # 设置界面
│   ├── SearchView.swift             # 搜索界面
│   └── Components/                  # 可复用组件
└── Resources/
    ├── Localization/                # 国际化资源
    └── Assets/                      # 图标资源
```

### 关键算法

#### 截图监测算法

```swift
class ScreenshotMonitor {
    private let metadataQuery = NSMetadataQuery()
    
    func startMonitoring() {
        metadataQuery.predicate = NSPredicate(format: "kMDItemScreenCaptureType != nil")
        metadataQuery.searchScopes = [NSMetadataQueryLocalComputerScope]
        metadataQuery.start()
    }
}
```

#### OCR 识别流程

1. 使用 Vision Framework 进行文本检测
2. 支持多语言识别（中英日）
3. 结果后处理和置信度过滤
4. 文本结构化提取

#### AI 分类决策

1. 收集 OCR 文本内容
2. 结合用户历史分类数据
3. 利用关键词匹配和语义分析
4. 生成分类建议和置信度评分

## 未来技术路线

### 短期目标（3-6个月）

- [ ] 优化 OCR 识别准确率
- [ ] 增强 AI 分类算法
- [ ] 支持更多截图来源
- [ ] 添加批量处理功能

### 中期目标（6-12个月）

- [ ] 云同步功能
- [ ] 移动端配套应用
- [ ] 高级搜索功能
- [ ] 数据统计分析

### 长期目标（1年以上）

- [ ] 多平台支持
- [ ] 企业级功能
- [ ] 第三方集成
- [ ] 开放 API 接口
