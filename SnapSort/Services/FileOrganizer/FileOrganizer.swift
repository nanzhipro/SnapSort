//
//  FileOrganizer.swift
//  SnapSort
//
//  Created by CursorAI on 2024-05-18.
//

import Foundation
import os
import os.log

/// File Organizer
///
/// Responsible for managing the organization and classification of screenshot files,
/// supporting moving screenshots to specified category directories,
/// and automatically handling filename conflicts, directory creation, etc. This component ensures
/// atomicity and safety of file operations, and provides detailed error handling and logging.
public final class FileOrganizer: FileOrganizerProtocol {
    /// Base directory URL for file operations
    public private(set) var baseDirectory: URL

    /// File system operation logger
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.snapsort.filesystem",
        category: "FileOrganizer")

    /// File manager instance
    private let fileManager = FileManager.default

    /// Initialize file organizer
    ///
    /// - Parameter baseDirectory: URL of the base directory, all category directories will be created under this directory
    /// - Throws: If the base directory is invalid or cannot be created, an appropriate exception will be thrown
    public init(baseDirectory: URL) throws {
        self.baseDirectory = baseDirectory
        try createDirectoryIfNeeded(at: baseDirectory)
        logger.info("Initialized file organizer with base directory: \(baseDirectory.path)")
    }

    /// Initialize file organizer
    ///
    /// - Parameter baseDirectoryPath: Path string of the base directory, all category directories will be created under this directory
    /// - Throws: If the base directory is invalid or cannot be created, an appropriate exception will be thrown
    public convenience init(baseDirectoryPath: String) throws {
        try self.init(baseDirectory: URL(fileURLWithPath: baseDirectoryPath, isDirectory: true))
    }

    /// 更新组织器的基础目录
    ///
    /// - Parameter path: 新的基础目录路径
    /// - Throws: 如果目录更新过程中发生错误，将抛出相应异常
    public func updateBaseDirectory(path: String) throws {
        let newBaseDirectory = URL(fileURLWithPath: path, isDirectory: true)
        try createDirectoryIfNeeded(at: newBaseDirectory)
        self.baseDirectory = newBaseDirectory
        logger.info("Updated base directory to: \(newBaseDirectory.path)")
    }

    /// 将截图文件移动到指定分类目录
    ///
    /// - Parameters:
    ///   - sourceURL: 截图文件的原始URL
    ///   - category: 目标分类名称，将作为子目录名
    /// - Returns: 移动后文件的新URL
    /// - Throws: 如果文件移动过程中发生错误，将抛出相应异常
    public func moveScreenshot(from sourceURL: URL, to category: String) throws -> URL {
        logger.debug("Moving file from \(sourceURL.lastPathComponent) to category '\(category)'")

        // 验证源文件是否存在
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            let error = FileOrganizerError.sourceFileNotFound(path: sourceURL.path)
            logger.error("Source file not found at path: \(sourceURL.path)")
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
            logger.info("Successfully moved file to: \(finalURL.path, privacy: .public)")
            return finalURL
        } catch {
            let organizerError = FileOrganizerError.fileMoveFailed(
                source: sourceURL.path,
                destination: finalURL.path,
                underlyingError: error
            )
            logger.error("Failed to move file: \(error.localizedDescription, privacy: .public)")
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
        logger.debug("Moving file using path string to category '\(category)'")
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = try moveScreenshot(from: sourceURL, to: category)
        return destinationURL.path
    }

    // MARK: - Private Helper Methods

    /// Create directory (if it doesn't exist)
    ///
    /// - Parameter url: URL of the directory to create
    /// - Throws: If directory creation fails, an exception will be thrown
    private func createDirectoryIfNeeded(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            logger.debug("Creating directory at \(url.path, privacy: .public)")
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
                logger.error(
                    "Failed to create directory: \(error.localizedDescription, privacy: .public)")
                throw organizerError
            }
        }
    }

    /// Resolve filename conflicts by adding counter suffixes to generate unique filenames
    ///
    /// - Parameter originalURL: Original file URL
    /// - Returns: A file URL that won't cause conflicts
    /// - Throws: If the file path cannot be resolved, an exception will be thrown
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
                logger.error("Failed to create unique filename after 1000 attempts")
                throw FileOrganizerError.fileAlreadyExists(path: originalURL.path)
            }
        }

        if finalURL != originalURL {
            logger.debug(
                "Resolved filename conflict: '\(originalURL.lastPathComponent)' → '\(finalURL.lastPathComponent)'"
            )
        }

        return finalURL
    }
}
