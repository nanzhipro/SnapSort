//
//  FileOrganizerError.swift
//  SnapSort
//
//  Created by CursorAI on 2024-05-18.
//

import Foundation

/// Errors that may occur during file organizer operations
///
/// This enumeration defines various error situations that may be encountered during file organization and movement,
/// including file operation failures, invalid paths, etc., and provides useful error descriptions and recovery suggestions.
public enum FileOrganizerError: Error {
    /// Source file does not exist
    case sourceFileNotFound(path: String)

    /// Failed to create directory
    case directoryCreationFailed(path: String, underlyingError: Error)

    /// Failed to move file
    case fileMoveFailed(source: String, destination: String, underlyingError: Error)

    /// Invalid file path
    case invalidFilePath(path: String)

    /// File already exists and cannot be overwritten
    case fileAlreadyExists(path: String)
}

extension FileOrganizerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .sourceFileNotFound(let path):
            return "Source file not found: \(path)"
        case .directoryCreationFailed(let path, _):
            return "Cannot create directory: \(path)"
        case .fileMoveFailed(let source, let destination, _):
            return "Cannot move file from \(source) to \(destination)"
        case .invalidFilePath(let path):
            return "Invalid file path: \(path)"
        case .fileAlreadyExists(let path):
            return "File already exists: \(path)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .sourceFileNotFound:
            return "The specified source file does not exist or cannot be accessed"
        case .directoryCreationFailed(_, let error):
            return "Error occurred when creating directory: \(error.localizedDescription)"
        case .fileMoveFailed(_, _, let error):
            return "Error occurred when moving file: \(error.localizedDescription)"
        case .invalidFilePath:
            return "The provided file path format is invalid or not supported"
        case .fileAlreadyExists:
            return
                "A file with the same name already exists at the destination, and overwrite option is not configured"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .sourceFileNotFound:
            return
                "Please check if the file path is correct, and ensure the file exists and is accessible"
        case .directoryCreationFailed:
            return
                "Please ensure the application has permission to create directories, and check available disk space"
        case .fileMoveFailed:
            return "Please ensure there is enough disk space and file operation permissions"
        case .invalidFilePath:
            return "Please provide a valid file path format"
        case .fileAlreadyExists:
            return "Please use a different filename, or enable the overwrite option"
        }
    }
}
