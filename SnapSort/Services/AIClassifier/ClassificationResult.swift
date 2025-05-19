//
//  ClassificationResult.swift
//  AIClassifier
//
//  Created by CursorAI on 2023-05-14.
//

import Foundation

/// 表示AI分类的结果
public struct ClassificationResult: Equatable {
    /// 分类结果的类别名称
    public let category: String

    /// 分类的置信度，值范围0-1，1表示最高置信度（可选）
    public let confidence: Double?

    /// 创建一个新的分类结果
    /// - Parameters:
    ///   - category: 分类结果的类别名称
    ///   - confidence: 分类的置信度，可选值
    public init(category: String, confidence: Double? = nil) {
        self.category = category
        self.confidence = confidence
    }
}

/// 表示LLM响应的JSON结构
struct ClassificationResponse: Codable {
    /// 分类的类别
    let category: String
    /// 分类的置信度，可选值
    let confidence: Double?
}
