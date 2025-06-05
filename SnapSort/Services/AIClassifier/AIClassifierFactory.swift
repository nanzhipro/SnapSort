//
//  AIClassifierFactory.swift
//  AIClassifier
//
//  Created by CursorAI on 2023-05-14.
//

import Foundation

/// Provides convenient factory methods for creating AIClassifier instances
public enum AIClassifierFactory {

    /// Create a classifier instance using DeepSeek API
    /// - Parameters:
    ///   - apiKey: DeepSeek API key
    ///   - baseURL: API base URL, defaults to DeepSeek API endpoint
    /// - Returns: Configured AI classifier instance
    public static func makeDeepSeekClassifier(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.deepseek.com/v1")!
    ) -> AIClassifier {
        let client = SimpleOpenAIClient(apiToken: apiKey, baseURL: baseURL)
        return AIClassifier(apiClient: client)
    }

    /// Create a classifier instance using OpenAI API
    /// - Parameters:
    ///   - apiKey: OpenAI API key
    /// - Returns: Configured AI classifier instance
    public static func makeOpenAIClassifier(apiKey: String) -> AIClassifier {
        let client = SimpleOpenAIClient(apiToken: apiKey)
        let classifier = AIClassifier(apiClient: client)
        classifier.modelName = "gpt-3.5-turbo"
        return classifier
    }

    /// Create a classifier instance using custom API endpoint
    /// - Parameters:
    ///   - apiKey: API key
    ///   - baseURL: API base URL
    ///   - modelName: Model name to use
    /// - Returns: Configured AI classifier instance
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
