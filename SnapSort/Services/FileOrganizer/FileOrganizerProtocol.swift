//
//  FileOrganizerProtocol.swift
//  SnapSort
//
//  Created by CursorAI on 2024-05-18.
//

import Foundation

/// 文件组织器协议，负责管理和组织截图文件
///
/// 该协议定义了文件组织器组件应提供的核心功能，包括将截图移动到指定分类目录，
/// 并提供相关的配置选项。实现此协议的类应当负责文件系统操作的原子性和安全性。
public protocol FileOrganizerProtocol {
    /// 组织器的基础目录，所有分类目录将在此目录下创建
    var baseDirectory: URL { get }

    /// 将截图文件移动到指定分类目录
    ///
    /// - Parameters:
    ///   - sourceURL: 截图文件的原始URL
    ///   - category: 目标分类名称，将作为子目录名
    /// - Returns: 移动后文件的新URL
    /// - Throws: 如果文件移动过程中发生错误，将抛出相应异常
    func moveScreenshot(from sourceURL: URL, to category: String) throws -> URL

    /// 将截图文件移动到指定分类目录，使用完整路径表示
    ///
    /// - Parameters:
    ///   - sourcePath: 截图文件的原始路径（字符串形式）
    ///   - category: 目标分类名称，将作为子目录名
    /// - Returns: 移动后文件的新路径（字符串形式）
    /// - Throws: 如果文件移动过程中发生错误，将抛出相应异常
    func moveScreenshot(from sourcePath: String, to category: String) throws -> String
}
