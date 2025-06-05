//
//  FileOrganizerProtocol.swift
//  SnapSort
//
//  Created by CursorAI on 2024-05-18.
//

import Foundation

/// File Organizer Protocol, responsible for managing and organizing screenshot files
///
/// This protocol defines the core functionality that a file organizer component should provide, including moving screenshots to specified category directories,
/// and providing related configuration options. Classes implementing this protocol should be responsible for the atomicity and safety of file system operations.
public protocol FileOrganizerProtocol {
    /// Base directory of the organizer, all category directories will be created under this directory
    var baseDirectory: URL { get }

    /// Update the organizer's base directory
    ///
    /// - Parameter path: Path to the new base directory
    /// - Throws: If an error occurs during directory update, an appropriate exception will be thrown
    func updateBaseDirectory(path: String) throws

    /// Move screenshot file to specified category directory
    ///
    /// - Parameters:
    ///   - sourceURL: Original URL of the screenshot file
    ///   - category: Target category name, used as subdirectory name
    /// - Returns: New URL of the file after moving
    /// - Throws: If an error occurs during file movement, an appropriate exception will be thrown
    func moveScreenshot(from sourceURL: URL, to category: String) throws -> URL

    /// Move screenshot file to specified category directory, using full path representation
    ///
    /// - Parameters:
    ///   - sourcePath: Original path of the screenshot file (as string)
    ///   - category: Target category name, used as subdirectory name
    /// - Returns: New path of the file after moving (as string)
    /// - Throws: If an error occurs during file movement, an appropriate exception will be thrown
    func moveScreenshot(from sourcePath: String, to category: String) throws -> String
}
