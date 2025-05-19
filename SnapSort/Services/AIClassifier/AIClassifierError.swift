//
//  AIClassifierError.swift
//  AIClassifier
//
//  Created by CursorAI on 2023-05-14.
//

import Foundation

/// AI分类器可能出现的错误类型
public enum AIClassifierError: Error, LocalizedError {
    /// API调用失败
    case apiError(String)
    /// 解析响应失败
    case parseError(String)
    /// 参数错误
    case invalidInput(String)

    /// 错误描述
    public var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "API call failed: \(message)"
        case .parseError(let message):
            return "Response parsing failed: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        }
    }
}
