//
//  AIClassifier.swift
//  AIClassifier
//
//  Created by CursorAI on 2023-05-14.
//

import Foundation
import os.log

// 导入自定义模型 - 使用SettingsModels中定义的Category
// 为了避免与系统内置Category类型冲突，我们需要明确指定使用自定义的Category类型
typealias CategoryModel = Category

/// AI智能分类器组件，用于对OCR识别后的文本进行智能分类
///
/// `AIClassifier` 使用DeepSeek API（与OpenAI兼容）对文本内容进行分类，将截图按照预定义的类别进行归类，
/// 支持用户自定义分类类别和关键词列表。组件设计遵循高内聚低耦合原则，易于集成到现有项目中。
///
/// ## 使用示例
///
/// ```swift
/// // 初始化分类器
/// let apiClient = SimpleOpenAIClient(apiToken: "your_api_key", baseURL: URL(string: "https://api.deepseek.com/v1")!)
/// let classifier = AIClassifier(apiClient: apiClient)
///
/// // 可选：自定义提示词模板
/// classifier.systemPromptTemplate = "你是一个专业的文本分类专家，请根据文本内容将其分类到以下类别之一：{categories}。输出必须是JSON格式。"
///
/// // 执行分类
/// do {
///     let result = try await classifier.classify(
///         text: "项目需求分析会议纪要",
///         categories: ["工作", "学习", "生活", "娱乐"]
///     )
///     print("分类结果: \(result.category)")
/// } catch {
///     print("分类失败: \(error)")
/// }
/// ```
///
/// ## 注意事项
///
/// 1. 需要提供有效的DeepSeek API密钥
/// 2. 建议提供足够的分类类别，以获得更准确的分类结果
/// 3. 默认使用"deepseek-chat"模型，可以通过`modelName`属性自定义
/// 4. 组件会处理API错误和响应解析错误，并通过`AIClassifierError`类型抛出
public final class AIClassifier {

    private let logger = Logger(subsystem: "com.snapsort.services", category: "AIClassifier")

    /// API客户端实例
    private let apiClient: OpenAIProtocol

    /// 使用的AI模型名称，默认为"deepseek-chat"
    public var modelName: String = "deepseek-chat"

    /// 系统提示词模板，用于指导AI如何执行分类任务
    public var systemPromptTemplate: String = """
        你是一个专业的文本分类专家。请根据提供的文本内容，将其分类到以下预定义类别中的一个。

        分类规则：
        1. 仔细分析文本内容中的关键词、主题和上下文
        2. 将文本内容与每个类别的关键词列表进行匹配
        3. 选择关键词匹配度最高的类别
        4. 如果多个类别的关键词匹配度相近，选择最相关的主题类别
        5. 必须从提供的类别列表中选择一个，不能创建新类别

        类别和关键词列表：
        {categories}

        输出要求：
        - 必须输出有效的JSON格式
        - 包含字段：category（类别名称）、confidence（置信度0-1）、matchedKeywords（匹配到的关键词列表）

        示例输出：
        {"category": "工作", "confidence": 0.92, "matchedKeywords": ["会议", "项目"]}
        """

    /// 用户提示词模板，用于构建与用户需求相关的提示
    public var userPromptTemplate: String = """
        请分析以下文本内容，根据关键词匹配将其分类到最合适的类别中：

        文本内容：
        {text}

        可选类别和关键词：
        {categories}

        分析步骤：
        1. 提取文本中的关键信息和主题词
        2. 与各类别的关键词列表进行匹配
        3. 计算匹配度并选择最佳类别
        4. 输出JSON格式结果

        请输出有效的JSON格式。
        """

    /// 初始化AI分类器
    /// - Parameter apiClient: OpenAI API客户端实例
    public init(apiClient: OpenAIProtocol) {
        self.apiClient = apiClient
    }

    /// 对文本内容进行智能分类（支持CategoryItem类型）
    /// - Parameters:
    ///   - text: 需要分类的文本内容，通常是OCR识别的结果
    ///   - categories: 预定义的分类类别列表，包含类别名和关键词
    /// - Returns: 分类结果，包含类别和可选的置信度
    /// - Throws: 分类过程中可能出现的错误，如API错误或解析错误
    func classify(text: String, categories: [CategoryItem]) async throws
        -> ClassificationResult
    {
        guard !text.isEmpty else {
            logger.error("Text content cannot be empty")
            throw AIClassifierError.invalidInput("Text content cannot be empty")
        }

        guard !categories.isEmpty else {
            logger.error("Category list cannot be empty")
            throw AIClassifierError.invalidInput("Category list cannot be empty")
        }

        // 格式化类别和关键词信息
        let categoriesInfo = categories.map { category in
            let keywordsString = category.keywords.joined(separator: "、")
            return "\(category.name)：[\(keywordsString)]"
        }.joined(separator: "\n")

        // 准备系统提示
        let systemPrompt = systemPromptTemplate.replacingOccurrences(
            of: "{categories}",
            with: categoriesInfo
        )

        // 准备用户提示
        let userPrompt =
            userPromptTemplate
            .replacingOccurrences(of: "{categories}", with: categoriesInfo)
            .replacingOccurrences(of: "{text}", with: text)

        // 准备消息
        let messages = [
            SimpleMessage(role: .system, content: systemPrompt),
            SimpleMessage(role: .user, content: userPrompt),
        ]

        logger.debug("Prepared messages for classification: \(messages, privacy: .private)")

        do {
            // 调用API并获取响应
            logger.info("Sending request to API...")
            let content = try await apiClient.chat(model: modelName, messages: messages)
            logger.debug("Received API response: \(content.prefix(100), privacy: .private)...")

            // 尝试预处理响应内容，移除可能导致JSON解析失败的内容
            let processedContent = preprocessJsonContent(content)
            logger.debug("Preprocessed JSON: \(processedContent, privacy: .private)")

            // 解析响应
            let decoder = JSONDecoder()
            guard let jsonData = processedContent.data(using: .utf8) else {
                logger.error("Unable to convert response content to data")
                throw AIClassifierError.parseError("Unable to convert response content to data")
            }

            do {
                let response = try decoder.decode(ClassificationResponse.self, from: jsonData)
                logger.info(
                    "Successfully classified text with category: \(response.category, privacy: .private), confidence: \(response.confidence ?? 0)"
                )
                return ClassificationResult(
                    category: response.category,
                    confidence: response.confidence
                )
            } catch {
                logger.error("JSON parsing failed: \(error.localizedDescription)")
                logger.debug("Attempting alternative parsing methods...")

                // 尝试使用备用方法解析
                if let result = tryAlternativeJsonParsing(
                    processedContent, availableCategories: categories.map { $0.name })
                {
                    logger.info(
                        "Alternative parsing succeeded with category: \(result.category, privacy: .private)"
                    )
                    return result
                }

                logger.error("Failed to parse JSON response: \(error.localizedDescription)")
                throw AIClassifierError.parseError(
                    "Failed to parse JSON response: \(error.localizedDescription)")
            }
        } catch let error as AIClassifierError {
            logger.error("Classification failed with error: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("API call failed: \(error.localizedDescription)")
            throw AIClassifierError.apiError("API call failed: \(error.localizedDescription)")
        }
    }

    /// 对文本内容进行智能分类（原有方法，保持向后兼容）
    /// - Parameters:
    ///   - text: 需要分类的文本内容，通常是OCR识别的结果
    ///   - categories: 预定义的分类类别列表
    /// - Returns: 分类结果，包含类别和可选的置信度
    /// - Throws: 分类过程中可能出现的错误，如API错误或解析错误
    public func classify(text: String, categories: [String]) async throws -> ClassificationResult {
        guard !text.isEmpty else {
            throw AIClassifierError.invalidInput("Text content cannot be empty")
        }

        guard !categories.isEmpty else {
            throw AIClassifierError.invalidInput("Category list cannot be empty")
        }

        // 准备系统提示
        let systemPrompt = systemPromptTemplate.replacingOccurrences(
            of: "{categories}",
            with: categories.joined(separator: "、")
        )

        // 准备用户提示
        let userPrompt =
            userPromptTemplate
            .replacingOccurrences(of: "{categories}", with: categories.joined(separator: "、"))
            .replacingOccurrences(of: "{text}", with: text)

        // 准备消息
        let messages = [
            SimpleMessage(role: .system, content: systemPrompt),
            SimpleMessage(role: .user, content: userPrompt),
        ]

        do {
            // 调用API并获取响应
            print("📤 Sending request to API...")
            let content = try await apiClient.chat(model: modelName, messages: messages)
            print("📥 Received API response: \(content.prefix(100))...")

            // 尝试预处理响应内容，移除可能导致JSON解析失败的内容
            let processedContent = preprocessJsonContent(content)
            print("🔄 Preprocessed JSON: \(processedContent)")

            // 解析响应
            let decoder = JSONDecoder()
            guard let jsonData = processedContent.data(using: .utf8) else {
                throw AIClassifierError.parseError("Unable to convert response content to data")
            }

            do {
                let response = try decoder.decode(ClassificationResponse.self, from: jsonData)
                return ClassificationResult(
                    category: response.category,
                    confidence: response.confidence
                )
            } catch {
                print("❌ JSON parsing failed: \(error.localizedDescription)")
                print("🔍 Attempting alternative parsing methods...")

                // 尝试使用备用方法解析
                if let result = tryAlternativeJsonParsing(
                    processedContent, availableCategories: categories)
                {
                    print("✅ Alternative parsing succeeded")
                    return result
                }

                throw AIClassifierError.parseError(
                    "Failed to parse JSON response: \(error.localizedDescription)")
            }
        } catch let error as AIClassifierError {
            throw error
        } catch {
            throw AIClassifierError.apiError("API call failed: \(error.localizedDescription)")
        }
    }

    /// 预处理JSON内容，移除可能导致解析失败的部分
    /// - Parameter content: 原始内容
    /// - Returns: 处理后的JSON字符串
    private func preprocessJsonContent(_ content: String) -> String {
        // 1. 移除可能的马克唐语法
        var processedContent = content

        // 2. 提取JSON部分 - 如果响应包含了JSON块
        if let jsonStart = processedContent.range(of: "{"),
            let jsonEnd = processedContent.range(of: "}", options: .backwards)
        {
            let startIndex = jsonStart.lowerBound
            let endIndex = jsonEnd.upperBound
            processedContent = String(processedContent[startIndex..<endIndex])
        }

        // 3. 移除特殊字符和空白
        processedContent = processedContent.trimmingCharacters(in: .whitespacesAndNewlines)

        return processedContent
    }

    /// 尝试通过备用方法解析JSON
    /// - Parameters:
    ///   - content: JSON字符串
    ///   - availableCategories: 可用的类别列表
    /// - Returns: 解析结果，如果失败则返回nil
    private func tryAlternativeJsonParsing(_ content: String, availableCategories: [String])
        -> ClassificationResult?
    {
        logger.debug(
            "Attempting alternative parsing methods, content: \(content, privacy: .private)")

        // 尝试使用JSONSerialization解析
        if let data = content.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let category = json["category"] as? String
        {
            let confidence = json["confidence"] as? Double
            logger.info(
                "JSONSerialization parsing succeeded: category=\(category, privacy: .private), confidence=\(confidence ?? 0)"
            )
            return ClassificationResult(category: category, confidence: confidence)
        }

        // 如果上面方法失败，尝试从文本中提取JSON对象
        if let jsonPattern = try? NSRegularExpression(
            pattern: "\\{[^\\{\\}]*\\\"category\\\"[^\\{\\}]*\\}",
            options: .caseInsensitive
        ) {
            let range = NSRange(location: 0, length: content.utf16.count)
            if let match = jsonPattern.firstMatch(in: content, options: [], range: range) {
                let matchRange = match.range
                if let range = Range(matchRange, in: content) {
                    let jsonString = String(content[range])
                    logger.debug("📋 Found JSON substring: \(jsonString, privacy: .private)")

                    // 尝试解析提取出的JSON子串
                    if let jsonData = jsonString.data(using: .utf8),
                        let json = try? JSONSerialization.jsonObject(with: jsonData)
                            as? [String: Any],
                        let category = json["category"] as? String
                    {
                        let confidence = json["confidence"] as? Double
                        logger.info(
                            "✅ Substring parsing succeeded: category=\(category, privacy: .private), confidence=\(confidence ?? 0)"
                        )
                        return ClassificationResult(category: category, confidence: confidence)
                    }
                }
            }
        }

        // 如果上面方法失败，通过正则表达式提取单独的字段
        logger.debug("🔍 Using regex to extract individual fields")

        // 提取类别
        var category: String?
        let categoryPattern = "\"category\"\\s*:\\s*\"([^\"]+)\""
        if let regex = try? NSRegularExpression(pattern: categoryPattern, options: []) {
            let range = NSRange(location: 0, length: content.utf16.count)
            if let match = regex.firstMatch(in: content, options: [], range: range),
                match.numberOfRanges > 1
            {
                let categoryRange = match.range(at: 1)
                if let range = Range(categoryRange, in: content) {
                    category = String(content[range])
                    logger.debug("📋 Extracted category: \(category ?? "", privacy: .private)")
                }
            }
        }

        // 提取置信度
        var confidence: Double?
        let confidencePattern = "\"confidence\"\\s*:\\s*([0-9.]+)"
        if let regex = try? NSRegularExpression(pattern: confidencePattern, options: []) {
            let range = NSRange(location: 0, length: content.utf16.count)
            if let match = regex.firstMatch(in: content, options: [], range: range),
                match.numberOfRanges > 1
            {
                let confidenceRange = match.range(at: 1)
                if let range = Range(confidenceRange, in: content),
                    let confValue = Double(String(content[range]))
                {
                    confidence = confValue
                    logger.debug("📋 Extracted confidence: \(confidence ?? 0, privacy: .private)")
                }
            }
        }

        // 如果找到了类别，则返回结果
        if let category = category {
            logger.info("✅ Regex parsing succeeded with category: \(category, privacy: .private)")
            return ClassificationResult(category: category, confidence: confidence)
        }

        // 最后的尝试 - 直接从文本中提取最可能的类别
        logger.debug(
            "⚠️ All JSON parsing methods failed, attempting to infer category directly from content")
        for possibleCategory in availableCategories {
            if content.localizedCaseInsensitiveContains("category")
                && content.localizedCaseInsensitiveContains(possibleCategory)
            {
                logger.info(
                    "✅ Successfully inferred category from text: \(possibleCategory, privacy: .private)"
                )
                return ClassificationResult(category: possibleCategory, confidence: nil)
            }
        }

        logger.error("❌ All parsing methods failed")
        return nil
    }
}
