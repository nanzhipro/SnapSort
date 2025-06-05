//
//  SettingsModels.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Foundation

/// AI Classification Mode
///
/// Defines the AI engine type used for screenshot classification, supporting local processing and cloud API modes.
/// Local processing offers better privacy, while cloud processing provides stronger AI capabilities.
enum AIClassificationMode: String, CaseIterable, Codable {
    /// Local AI processing mode
    case local = "local"
    /// Cloud API processing mode
    case cloud = "cloud"

    /// Get localized display name for mode
    /// - Returns: Display text based on current locale
    var localizedName: String {
        switch self {
        case .local:
            return NSLocalizedString("ai.mode.local", comment: "本地处理")
        case .cloud:
            return NSLocalizedString("ai.mode.cloud", comment: "云端处理")
        }
    }
}

/// Screenshot Category Model
///
/// Represents user-defined screenshot classification rules with category name, associated keywords, and enabled status.
/// Supports automatic keyword-based matching for intelligent screenshot file categorization.
struct Category: Identifiable, Codable, Hashable {
    /// Unique identifier
    let id = UUID()
    /// Category name
    var name: String
    /// Associated keyword list for automatic matching
    var keywords: [String]
    /// Whether this category is enabled
    var isEnabled: Bool = true
    /// Creation timestamp
    var createdAt: Date = Date()

    /// Create a new category
    /// - Parameters:
    ///   - name: Category name
    ///   - keywords: Associated keyword list, empty by default
    init(name: String, keywords: [String] = []) {
        self.name = name
        self.keywords = keywords
    }
}

/// Notification Settings
///
/// Manages application notification behavior, including display of various notification types and sound alerts.
/// Provides granular notification control, allowing users to enable or disable specific notification types.
struct NotificationSettings: Codable {
    /// Whether notifications are enabled
    var isEnabled: Bool = true
    /// Whether to show classification result notifications
    var showClassificationResult: Bool = true
    /// Whether to show error message notifications
    var showErrorMessages: Bool = true
    /// Whether sound alerts are enabled
    var soundEnabled: Bool = false

    /// Default notification settings
    static let `default` = NotificationSettings()
}

/// File Storage Settings
///
/// Manages screenshot file storage location and organization, including base directory and subfolder creation rules.
/// Supports flexible file organization strategies to ensure orderly storage of screenshots.
struct StorageSettings: Codable {
    /// Base storage directory path
    var baseDirectory: String = ""
    /// Whether to create subfolder for each category
    var createSubfolders: Bool = true
    /// Whether to preserve original filenames
    var preserveOriginalFilenames: Bool = true
    /// Maximum file size limit (MB)
    var maxFileSize: Int = 50

    /// Default storage settings
    static let `default` = StorageSettings()
}
