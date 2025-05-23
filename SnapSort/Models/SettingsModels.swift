//
//  SettingsModels.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Foundation

/// AI分类处理模式
///
/// 定义截图分类时使用的AI引擎类型，支持本地处理和云端API两种模式。
/// 本地处理提供更好的隐私保护，云端处理提供更强的AI能力。
enum AIClassificationMode: String, CaseIterable, Codable {
    /// 本地AI处理模式
    case local = "local"
    /// 云端API处理模式
    case cloud = "cloud"

    /// 获取模式的本地化显示名称
    /// - Returns: 根据当前语言环境返回相应的显示文本
    var localizedName: String {
        switch self {
        case .local:
            return NSLocalizedString("ai.mode.local", comment: "本地处理")
        case .cloud:
            return NSLocalizedString("ai.mode.cloud", comment: "云端处理")
        }
    }
}

/// 截图分类类别模型
///
/// 表示用户自定义的截图分类规则，包含类别名称、关联关键词以及启用状态。
/// 支持基于关键词的自动匹配功能，用于智能分类截图文件。
struct Category: Identifiable, Codable, Hashable {
    /// 唯一标识符
    let id = UUID()
    /// 类别名称
    var name: String
    /// 关联的关键词列表，用于自动匹配
    var keywords: [String]
    /// 是否启用此类别
    var isEnabled: Bool = true
    /// 创建时间
    var createdAt: Date = Date()

    /// 创建新的分类类别
    /// - Parameters:
    ///   - name: 类别名称
    ///   - keywords: 关联关键词列表，默认为空
    init(name: String, keywords: [String] = []) {
        self.name = name
        self.keywords = keywords
    }
}

/// 通知设置配置
///
/// 管理应用程序的通知行为，包括是否显示各类通知消息和声音提示。
/// 提供细粒度的通知控制，允许用户根据需要启用或禁用特定类型的通知。
struct NotificationSettings: Codable {
    /// 是否启用通知
    var isEnabled: Bool = true
    /// 是否显示分类结果通知
    var showClassificationResult: Bool = true
    /// 是否显示错误消息通知
    var showErrorMessages: Bool = true
    /// 是否启用声音提示
    var soundEnabled: Bool = false

    /// 默认通知设置
    static let `default` = NotificationSettings()
}

/// 文件存储设置配置
///
/// 管理截图文件的存储位置和组织方式，包括基础目录、子文件夹创建规则等。
/// 支持灵活的文件组织策略，确保截图文件有序存储。
struct StorageSettings: Codable {
    /// 基础存储目录路径
    var baseDirectory: String = ""
    /// 是否为每个分类创建子文件夹
    var createSubfolders: Bool = true
    /// 是否保留原始文件名
    var preserveOriginalFilenames: Bool = true
    /// 最大文件大小限制（MB）
    var maxFileSize: Int = 50

    /// 默认存储设置
    static let `default` = StorageSettings()
}
