//
//  OpenAIProtocol.swift
//  AIClassifier
//
//  Created by CursorAI on 2023-05-14.
//

import Foundation
import OpenAI

/// Define simplified chat message structure
public struct SimpleMessage {
    /// Message role
    public enum Role: String {
        case system
        case user
        case assistant
    }

    /// Message role
    public let role: Role
    /// Message content
    public let content: String

    /// Create a new chat message
    /// - Parameters:
    ///   - role: Message role
    ///   - content: Message content
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

/// Protocol defining interaction with OpenAI API
public protocol OpenAIProtocol {
    /// Send chat request and get response
    /// - Parameters:
    ///   - model: Model name
    ///   - messages: Chat message list
    /// - Returns: Chat response content
    func chat(model: String, messages: [SimpleMessage]) async throws -> String
}

/// OpenAI服务的简单实现
public class SimpleOpenAIClient: OpenAIProtocol {
    private let apiToken: String
    private let baseURL: URL

    /// 初始化客户端
    /// - Parameters:
    ///   - apiToken: API令牌
    ///   - baseURL: API基础URL，默认为OpenAI的端点
    public init(apiToken: String, baseURL: URL = URL(string: "https://api.openai.com/v1")!) {
        self.apiToken = apiToken
        self.baseURL = baseURL
    }

    /// 发送聊天请求并获取响应
    /// - Parameters:
    ///   - model: 模型名称
    ///   - messages: 聊天消息列表
    /// - Returns: 聊天响应内容
    public func chat(model: String, messages: [SimpleMessage]) async throws -> String {
        // 构建请求URL
        let url = baseURL.appendingPathComponent("chat/completions")
        print("🔗 API request URL: \(url.absoluteString)")

        // 准备请求体
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
        ]

        // 将请求体转换为JSON数据
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        print("📦 Request data size: \(jsonData.count) bytes")

        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        // 发送请求
        print("⏳ Sending request to API server...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📊 Response received, data size: \(data.count) bytes")

        // 检查HTTP响应状态码
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "SimpleOpenAIClient", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }

        print("🔢 HTTP status code: \(httpResponse.statusCode)")

        // 记录响应头信息以辅助调试
        print("📋 Response headers:")
        for (key, value) in httpResponse.allHeaderFields {
            print("  \(key): \(value)")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API error response: \(errorMessage)")
            throw NSError(
                domain: "SimpleOpenAIClient", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        // 记录原始JSON响应，帮助调试
        if let rawJson = String(data: data, encoding: .utf8) {
            print("📄 Raw JSON response (first 100 chars): \(rawJson.prefix(100))...")
        }

        // 解析响应
        do {
            guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                print("⚠️ Unable to parse response as dictionary")
                throw NSError(
                    domain: "SimpleOpenAIClient", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to parse response as dictionary"])
            }

            // 检查是否存在错误字段
            if let error = responseDict["error"] as? [String: Any],
                let message = error["message"] as? String
            {
                print("❌ API returned error: \(message)")
                throw NSError(
                    domain: "SimpleOpenAIClient", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "API error: \(message)"])
            }

            // 尝试不同的响应格式解析
            if let choices = responseDict["choices"] as? [[String: Any]] {
                if let firstChoice = choices.first {
                    // 常规OpenAI格式
                    if let message = firstChoice["message"] as? [String: Any],
                        let content = message["content"] as? String
                    {
                        return content
                    }

                    // 替代格式 - 有些API直接在choice中包含text/content
                    if let content = firstChoice["text"] as? String {
                        return content
                    }

                    if let content = firstChoice["content"] as? String {
                        return content
                    }

                    // 打印出第一个choice的所有键，帮助调试
                    print("🔑 Response choice keys: \(firstChoice.keys.joined(separator: ", "))")
                }

                // 如果所有尝试都失败，但响应中有内容，尝试格式化并返回
                print(
                    "⚠️ Could not find content in standard location, attempting alternative parsing")
                if let choicesData = try? JSONSerialization.data(
                    withJSONObject: choices, options: .prettyPrinted),
                    let choicesString = String(data: choicesData, encoding: .utf8)
                {
                    print("📝 Choices content: \(choicesString)")
                    return choicesString
                }
            }

            // 最后的尝试：直接返回整个响应的字符串形式
            if let fullResponseData = try? JSONSerialization.data(
                withJSONObject: responseDict, options: .prettyPrinted),
                let fullResponseString = String(data: fullResponseData, encoding: .utf8)
            {
                print("⚠️ Returning full response string")
                return fullResponseString
            }

            throw NSError(
                domain: "SimpleOpenAIClient", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to parse response"])
        } catch {
            print("❌ Response parsing error: \(error.localizedDescription)")
            // 在解析失败的情况下，尝试直接返回原始响应字符串
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("⚠️ Parsing failed, returning raw response string")
                return rawResponse
            }
            throw error
        }
    }
}
