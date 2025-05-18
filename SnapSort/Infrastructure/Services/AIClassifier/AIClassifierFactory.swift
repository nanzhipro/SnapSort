//
//  AIClassifierFactory.swift
//  AIClassifier
//
//  Created by CursorAI on 2023-05-14.
//

import Foundation

/// 提供创建AIClassifier实例的简便工厂方法
public enum AIClassifierFactory {

    /// 创建一个使用DeepSeek API的分类器实例
    /// - Parameters:
    ///   - apiKey: DeepSeek API密钥
    ///   - baseURL: API基础URL，默认为DeepSeek API地址
    /// - Returns: 配置好的AI分类器实例
    public static func makeDeepSeekClassifier(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.deepseek.com/v1")!
    ) -> AIClassifier {
        let client = SimpleOpenAIClient(apiToken: apiKey, baseURL: baseURL)
        return AIClassifier(apiClient: client)
    }

    /// 创建一个使用OpenAI API的分类器实例
    /// - Parameters:
    ///   - apiKey: OpenAI API密钥
    /// - Returns: 配置好的AI分类器实例
    public static func makeOpenAIClassifier(apiKey: String) -> AIClassifier {
        let client = SimpleOpenAIClient(apiToken: apiKey)
        let classifier = AIClassifier(apiClient: client)
        classifier.modelName = "gpt-3.5-turbo"
        return classifier
    }

    /// 创建一个使用自定义API端点的分类器实例
    /// - Parameters:
    ///   - apiKey: API密钥
    ///   - baseURL: API基础URL
    ///   - modelName: 要使用的模型名称
    /// - Returns: 配置好的AI分类器实例
    public static func makeCustomClassifier(
        apiKey: String,
        baseURL: URL,
        modelName: String
    ) -> AIClassifier {
        let client = SimpleOpenAIClient(apiToken: apiKey, baseURL: baseURL)
        let classifier = AIClassifier(apiClient: client)
        classifier.modelName = modelName
        return classifier
    }
}
