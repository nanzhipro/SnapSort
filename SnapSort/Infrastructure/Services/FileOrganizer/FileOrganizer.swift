//
//  FileOrganizer.swift
//  SnapSort
//
//  Created by CursorAI on 2024-05-18.
//

import Foundation
import os.log

/// 文件组织器
///
/// 负责管理截图文件的组织和分类，支持将截图移动到指定分类目录，
/// 并自动处理文件名冲突、目录创建等操作。该组件确保文件操作的
/// 原子性和安全性，并提供详细的错误处理和日志记录。
public final class FileOrganizer: FileOrganizerProtocol {
    /// 文件操作的基础目录URL
    public let baseDirectory: URL

    /// 文件系统操作日志记录器
    private let logger = FileSystemLogger(category: "FileOrganizer")

    /// 文件管理器实例
    private let fileManager = FileManager.default

    /// 初始化文件组织器
    ///
    /// - Parameter baseDirectory: 基础目录的URL，所有分类目录将在此目录下创建
    /// - Throws: 如果基础目录无效或无法创建，将抛出相应异常
    public init(baseDirectory: URL) throws {
        self.baseDirectory = baseDirectory
        try createDirectoryIfNeeded(at: baseDirectory)
        logger.info("初始化文件组织器，基础目录: \(baseDirectory.path)")
    }

    /// 初始化文件组织器
    ///
    /// - Parameter baseDirectoryPath: 基础目录的路径字符串，所有分类目录将在此目录下创建
    /// - Throws: 如果基础目录无效或无法创建，将抛出相应异常
    public convenience init(baseDirectoryPath: String) throws {
        try self.init(baseDirectory: URL(fileURLWithPath: baseDirectoryPath, isDirectory: true))
    }

    /// 将截图文件移动到指定分类目录
    ///
    /// - Parameters:
    ///   - sourceURL: 截图文件的原始URL
    ///   - category: 目标分类名称，将作为子目录名
    /// - Returns: 移动后文件的新URL
    /// - Throws: 如果文件移动过程中发生错误，将抛出相应异常
    public func moveScreenshot(from sourceURL: URL, to category: String) throws -> URL {
        logger.info("开始移动文件: \(sourceURL.path) -> 分类: \(category)")

        // 验证源文件是否存在
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            let error = FileOrganizerError.sourceFileNotFound(path: sourceURL.path)
            logger.error("源文件不存在", error: error)
            throw error
        }

        // 创建分类目录
        let categoryDirectory = baseDirectory.appendingPathComponent(category, isDirectory: true)
        try createDirectoryIfNeeded(at: categoryDirectory)

        // 准备目标文件URL，处理潜在的文件名冲突
        let destinationURL = categoryDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        let finalURL = try resolveDuplicateFilename(at: destinationURL)

        // 移动文件
        do {
            try fileManager.moveItem(at: sourceURL, to: finalURL)
            logger.info("成功移动文件到: \(finalURL.path)")
            return finalURL
        } catch {
            let organizerError = FileOrganizerError.fileMoveFailed(
                source: sourceURL.path,
                destination: finalURL.path,
                underlyingError: error
            )
            logger.error("移动文件失败", error: organizerError)
            throw organizerError
        }
    }

    /// 将截图文件移动到指定分类目录，使用完整路径表示
    ///
    /// - Parameters:
    ///   - sourcePath: 截图文件的原始路径（字符串形式）
    ///   - category: 目标分类名称，将作为子目录名
    /// - Returns: 移动后文件的新路径（字符串形式）
    /// - Throws: 如果文件移动过程中发生错误，将抛出相应异常
    public func moveScreenshot(from sourcePath: String, to category: String) throws -> String {
        logger.info("使用路径字符串调用移动文件: \(sourcePath) -> 分类: \(category)")
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = try moveScreenshot(from: sourceURL, to: category)
        return destinationURL.path
    }

    // MARK: - 私有辅助方法

    /// 创建目录（如果不存在）
    ///
    /// - Parameter url: 要创建的目录URL
    /// - Throws: 如果目录创建失败，将抛出异常
    private func createDirectoryIfNeeded(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            logger.debug("创建目录: \(url.path)")
            do {
                try fileManager.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                let organizerError = FileOrganizerError.directoryCreationFailed(
                    path: url.path,
                    underlyingError: error
                )
                logger.error("创建目录失败", error: organizerError)
                throw organizerError
            }
        }
    }

    /// 解决文件名冲突，通过添加计数器后缀生成唯一文件名
    ///
    /// - Parameter originalURL: 原始文件URL
    /// - Returns: 一个不会产生冲突的文件URL
    /// - Throws: 如果无法解析文件路径，将抛出异常
    private func resolveDuplicateFilename(at originalURL: URL) throws -> URL {
        var counter = 1
        var finalURL = originalURL

        let fileExtension = originalURL.pathExtension
        let baseFilename = originalURL.deletingPathExtension().lastPathComponent

        // 如果文件已存在，则添加计数后缀
        while fileManager.fileExists(atPath: finalURL.path) {
            let newFilename = "\(baseFilename)_\(counter).\(fileExtension)"
            finalURL = originalURL.deletingLastPathComponent().appendingPathComponent(newFilename)
            counter += 1

            // 防止无限循环
            if counter > 1000 {
                logger.error("无法创建唯一文件名，超过最大尝试次数")
                throw FileOrganizerError.fileAlreadyExists(path: originalURL.path)
            }
        }

        if finalURL != originalURL {
            logger.debug(
                "文件名冲突解决: \(originalURL.lastPathComponent) -> \(finalURL.lastPathComponent)")
        }

        return finalURL
    }
}
