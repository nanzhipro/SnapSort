//
//  AIClassifier.swift
//  AIClassifier
//
//  Created by CursorAI on 2023-05-14.
//

import Foundation
import os.log

// Import custom models - using Category defined in SettingsModels
// To avoid conflicts with the built-in Category type, we need to explicitly specify our custom Category type
typealias CategoryModel = Category

/// AI Intelligent Classifier Component for classifying text after OCR recognition
///
/// `AIClassifier` uses the DeepSeek API (OpenAI compatible) to classify text content, categorizing screenshots according to predefined categories,
/// supporting user-defined categories and keyword lists. The component follows high cohesion and low coupling principles for easy integration.
///
/// ## Usage Example
///
/// ```swift
/// // Initialize classifier
/// let apiClient = SimpleOpenAIClient(apiToken: "your_api_key", baseURL: URL(string: "https://api.deepseek.com/v1")!)
/// let classifier = AIClassifier(apiClient: apiClient)
///
/// // Optional: customize prompt template
/// classifier.systemPromptTemplate = "You are a professional text classification expert. Please classify the text into one of these categories: {categories}. Output must be in JSON format."
///
/// // Perform classification
/// do {
///     let result = try await classifier.classify(
///         text: "Project requirements analysis meeting minutes",
///         categories: ["Work", "Study", "Life", "Entertainment"]
///     )
///     print("Classification result: \(result.category)")
/// } catch {
///     print("Classification failed: \(error)")
/// }
/// ```
///
/// ## Notes
///
/// 1. A valid DeepSeek API key is required
/// 2. Providing sufficient categories is recommended for more accurate classification results
/// 3. Uses "deepseek-chat" model by default, can be customized via the `modelName` property
/// 4. The component handles API errors and response parsing errors, throwing them as `AIClassifierError` types
public final class AIClassifier {

    private let logger = Logger(subsystem: "com.snapsort.services", category: "AIClassifier")

    /// API client instance
    private let apiClient: OpenAIProtocol

    /// AI model name used, defaults to "deepseek-chat"
    public var modelName: String = "deepseek-chat"

    /// System prompt template, guides the AI on how to perform classification tasks
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

    /// User prompt template, for building prompts related to user requirements
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

    /// Initialize AI classifier
    /// - Parameter apiClient: OpenAI API client instance
    public init(apiClient: OpenAIProtocol) {
        self.apiClient = apiClient
    }

    /// Intelligently classify text content (supports CategoryItem type)
    /// - Parameters:
    ///   - text: Text content to classify, typically OCR recognition results
    ///   - categories: Predefined category list, containing category names and keywords
    /// - Returns: Classification result, including category and optional confidence level
    /// - Throws: Errors that may occur during classification, such as API errors or parsing errors
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

    /// Intelligently classify text content (original method, maintained for backward compatibility)
    /// - Parameters:
    ///   - text: Text content to classify, typically OCR recognition results
    ///   - categories: Predefined category list
    /// - Returns: Classification result, including category and optional confidence level
    /// - Throws: Errors that may occur during classification, such as API errors or parsing errors
    public func classify(text: String, categories: [String]) async throws -> ClassificationResult {
        guard !text.isEmpty else {
            throw AIClassifierError.invalidInput("Text content cannot be empty")
        }

        guard !categories.isEmpty else {
            throw AIClassifierError.invalidInput("Category list cannot be empty")
        }

        // Prepare system prompt
        let systemPrompt = systemPromptTemplate.replacingOccurrences(
            of: "{categories}",
            with: categories.joined(separator: "、")
        )

        // Prepare user prompt
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
            // Call API and get response
            print("📤 Sending request to API...")
            let content = try await apiClient.chat(model: modelName, messages: messages)
            print("📥 Received API response: \(content.prefix(100))...")

            // Pre-process response content, remove content that may cause JSON parsing to fail
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

    /// Preprocess JSON content, remove parts that may cause parsing failures
    /// - Parameter content: Original content
    /// - Returns: Processed JSON string
    private func preprocessJsonContent(_ content: String) -> String {
        // 1. Remove possible markdown syntax
        var processedContent = content

        // 2. Extract JSON part - if the response contains JSON blocks
        if let jsonStart = processedContent.range(of: "{"),
            let jsonEnd = processedContent.range(of: "}", options: .backwards)
        {
            let startIndex = jsonStart.lowerBound
            let endIndex = jsonEnd.upperBound
            processedContent = String(processedContent[startIndex..<endIndex])
        }

        // 3. Remove special characters and whitespace
        processedContent = processedContent.trimmingCharacters(in: .whitespacesAndNewlines)

        return processedContent
    }

    /// Attempt to parse JSON using alternative methods
    /// - Parameters:
    ///   - content: JSON string
    ///   - availableCategories: List of available categories
    /// - Returns: Parsing result, returns nil if failed
    private func tryAlternativeJsonParsing(_ content: String, availableCategories: [String])
        -> ClassificationResult?
    {
        logger.debug(
            "Attempting alternative parsing methods, content: \(content, privacy: .private)")

        // Try parsing with JSONSerialization
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

        // If the above method fails, try extracting JSON objects from the text
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

                    // Try parsing the extracted JSON substring
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

        // If the above method fails, extract individual fields using regular expressions
        logger.debug("🔍 Using regex to extract individual fields")

        // Extract category
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

        // Extract confidence
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

        // If a category is found, return the result
        if let category = category {
            logger.info("✅ Regex parsing succeeded with category: \(category, privacy: .private)")
            return ClassificationResult(category: category, confidence: confidence)
        }

        // Final attempt - directly extract the most likely category from the text
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
