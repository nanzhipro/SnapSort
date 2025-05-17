# AIClassifier 组件

AIClassifier 是 SnapSort 应用的核心组件之一，负责对 OCR 识别的文本进行智能分类，将截图自动分类到用户定义的类别中。

## 组件架构

- `AIClassifierProtocol`: 定义 AI 分类器的接口
- `AIClassifier`: 主要实现类，使用 OpenAI API 进行文本分类
- `MacPawOpenAIAdapter`: 适配 MacPaw OpenAI SDK 的适配器
- `AIClassifierFactory`: 工厂类，简化分类器的创建和配置

## 用法示例

### 基本用法

```swift
import SnapSort

// 使用工厂类创建分类器
let classifier = AIClassifierFactory.createDeepSeekClassifier(
    apiKey: "your-deepseek-api-key"
)

// 定义类别列表
let categories = ["工作", "开发", "设计", "个人"]

// 进行分类
do {
    let result = try await classifier.classifyText("SwiftUI 的新特性...", categories: categories)
    print("分类结果: \(result.category)")
    print("置信度: \(result.confidence)")
    print("理由: \(result.reasoning)")
} catch {
    print("分类失败: \(error)")
}
```

### 自定义提示词

```swift
let customSystemPrompt = """
你是一个专业的文本分析助手，你需要将给定的文本分类到最合适的预定义类别中。
分析应当考虑文本的核心主题、关键术语和整体语境。
"""

let customUserTemplate = """
请分析以下文本，并分类到这些类别之一: %@

文本内容：
%@

请以JSON格式返回，包含类别、置信度和推理过程。
"""

let classifier = AIClassifierFactory.createDeepSeekClassifier(
    apiKey: "your-api-key",
    systemPrompt: customSystemPrompt,
    userPromptTemplate: customUserTemplate
)
```

### 测试用途的模拟分类器

```swift
// 创建模拟响应
let mockResponses = [
    "测试文本1": ClassificationResult(
        category: "开发", 
        confidence: 0.9, 
        reasoning: "包含编程相关内容"
    )
]

// 创建模拟分类器
let mockClassifier = AIClassifierFactory.createMockClassifier(
    mockResponses: mockResponses
)

// 使用方式与真实分类器相同
let result = try await mockClassifier.classifyText("测试文本1", categories: ["开发", "设计"])
```

## 错误处理

AIClassifier 可能抛出以下错误：

- `AIClassifierError.emptyText`: 输入文本为空
- `AIClassifierError.noCategoriesProvided`: 未提供任何分类选项
- `AIClassifierError.invalidResponseFormat`: AI 响应格式无效
- `AIClassifierError.serviceError`: AI 服务调用出错

## 配置选项

- `model`: 使用的模型名称，默认为 "deepseek-chat"
- `systemPrompt`: 系统提示词，指导 AI 如何进行分类
- `userPromptTemplate`: 用户提示词模板，结合具体文本和类别
