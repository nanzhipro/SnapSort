//
//  ClassificationResult.swift
//  AIClassifier
//
//  Created by CursorAI on 2023-05-14.
//

import Foundation

/// Represents AI classification result
public struct ClassificationResult: Equatable {
    /// Category name of classification result
    public let category: String

    /// Classification confidence, range 0-1, 1 being highest confidence (optional)
    public let confidence: Double?

    /// Create a new classification result
    /// - Parameters:
    ///   - category: Category name of classification result
    ///   - confidence: Classification confidence, optional value
    public init(category: String, confidence: Double? = nil) {
        self.category = category
        self.confidence = confidence
    }
}

/// Represents JSON structure of LLM response
struct ClassificationResponse: Codable {
    /// Classification category
    let category: String
    /// Classification confidence, optional value
    let confidence: Double?
}
