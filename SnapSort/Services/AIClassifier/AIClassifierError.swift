//
//  AIClassifierError.swift
//  AIClassifier
//
//  Created by CursorAI on 2023-05-14.
//

import Foundation

/// Error types that may occur in AI classifier
public enum AIClassifierError: Error, LocalizedError {
    /// API call failure
    case apiError(String)
    /// Response parsing failure
    case parseError(String)
    /// Parameter error
    case invalidInput(String)

    /// Error description
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
