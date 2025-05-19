//
//  FileOrganizerError.swift
//  SnapSort
//
//  Created by CursorAI on 2024-05-18.
//

import Foundation

/// 文件组织器操作过程中可能出现的错误
///
/// 此枚举定义了在文件组织和移动过程中可能遇到的各种错误情况，
/// 包括文件操作失败、路径无效等，并提供有用的错误描述和恢复建议。
public enum FileOrganizerError: Error {
    /// 源文件不存在
    case sourceFileNotFound(path: String)

    /// 创建目录失败
    case directoryCreationFailed(path: String, underlyingError: Error)

    /// 移动文件失败
    case fileMoveFailed(source: String, destination: String, underlyingError: Error)

    /// 无效的文件路径
    case invalidFilePath(path: String)

    /// 文件已存在且无法覆盖
    case fileAlreadyExists(path: String)
}

extension FileOrganizerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .sourceFileNotFound(let path):
            return "源文件未找到：\(path)"
        case .directoryCreationFailed(let path, _):
            return "无法创建目录：\(path)"
        case .fileMoveFailed(let source, let destination, _):
            return "无法移动文件 从 \(source) 到 \(destination)"
        case .invalidFilePath(let path):
            return "无效的文件路径：\(path)"
        case .fileAlreadyExists(let path):
            return "文件已存在：\(path)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .sourceFileNotFound:
            return "指定的源文件不存在或无法访问"
        case .directoryCreationFailed(_, let error):
            return "创建目录时发生错误：\(error.localizedDescription)"
        case .fileMoveFailed(_, _, let error):
            return "移动文件时发生错误：\(error.localizedDescription)"
        case .invalidFilePath:
            return "提供的文件路径格式无效或不受支持"
        case .fileAlreadyExists:
            return "目标位置已存在同名文件，且未配置覆盖选项"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .sourceFileNotFound:
            return "请检查文件路径是否正确，并确保文件存在且有访问权限"
        case .directoryCreationFailed:
            return "请确保应用有创建目录的权限，并检查磁盘空间"
        case .fileMoveFailed:
            return "请确保有足够的磁盘空间和文件操作权限"
        case .invalidFilePath:
            return "请提供有效的文件路径格式"
        case .fileAlreadyExists:
            return "请使用不同的文件名，或启用覆盖选项"
        }
    }
}
