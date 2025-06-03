//
//  CategoryModels.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Foundation

/// 分类项目模型
///
/// 表示用户定义的截图分类，包含分类名称和关键词列表。
/// 用于AI分类和文件组织功能，支持基于关键词的自动分类。
public struct CategoryItem: Identifiable, Codable {
    public let id = UUID()
    public var name: String
    public var keywords: [String]

    public init(name: String, keywords: [String]) {
        self.name = name
        self.keywords = keywords
    }
}
