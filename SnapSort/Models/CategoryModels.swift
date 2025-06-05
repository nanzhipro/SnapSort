//
//  CategoryModels.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Foundation

/// Category Item Model
///
/// Represents user-defined screenshot categories with name and keyword list.
/// Used for AI classification and file organization, supporting keyword-based auto-categorization.
public struct CategoryItem: Identifiable, Codable {
    public let id = UUID()
    public var name: String
    public var keywords: [String]

    public init(name: String, keywords: [String]) {
        self.name = name
        self.keywords = keywords
    }
}
