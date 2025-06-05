//
//  FileOrganizerExample.swift
//  SnapSort
//
//  Created by CursorAI on 2024-05-18.
//

import Foundation

/// FileOrganizer Usage Example
///
/// This file demonstrates how to use the FileOrganizer component to manage and organize screenshot files.
/// This example is for API usage demonstration only, not actual application code.
struct FileOrganizerExample {

    /// Run example code
    static func runExample() {
        do {
            // 1. Create a FileOrganizer instance based on user's screenshot directory
            let screenshotsDir = try getDefaultScreenshotsDirectory()
            let organizer = try FileOrganizer(baseDirectory: screenshotsDir)

            // 2. Assume we have a screenshot file
            let sampleScreenshotPath = "/path/to/your/screenshot.png"

            // 3. Move screenshot to "Work" category
            // Note: In real application, ensure file paths are valid
            if FileManager.default.fileExists(atPath: sampleScreenshotPath) {
                do {
                    let newPath = try organizer.moveScreenshot(
                        from: sampleScreenshotPath, to: "Work")
                    print("Screenshot moved to: \(newPath)")
                } catch {
                    print("Failed to move file: \(error.localizedDescription)")
                }
            } else {
                print("Example file doesn't exist, this is just a demonstration")
            }
        } catch {
            print("Failed to initialize FileOrganizer: \(error.localizedDescription)")
        }
    }

    /// Get default screenshots directory
    private static func getDefaultScreenshotsDirectory() throws -> URL {
        // On macOS, default screenshot directory is usually '~/Desktop' or custom location
        // We use an example directory here
        let picturesDir = try FileManager.default.url(
            for: .picturesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        return picturesDir.appendingPathComponent("Screenshots", isDirectory: true)
    }
}
