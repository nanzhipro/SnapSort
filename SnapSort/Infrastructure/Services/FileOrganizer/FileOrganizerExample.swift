//
//  FileOrganizerExample.swift
//  SnapSort
//
//  Created by CursorAI on 2024-05-18.
//

import Foundation

/// FileOrganizer使用示例
///
/// 本文件展示了如何使用FileOrganizer组件来管理和组织截图文件。
/// 这个示例仅用于展示API的使用方法，而不是实际的应用代码。
struct FileOrganizerExample {

    /// 运行示例代码
    static func runExample() {
        do {
            // 1. 创建一个基于用户截图目录的FileOrganizer实例
            let screenshotsDir = try getDefaultScreenshotsDirectory()
            let organizer = try FileOrganizer(baseDirectory: screenshotsDir)

            // 2. 假设我们有一个截图文件
            let sampleScreenshotPath = "/path/to/your/screenshot.png"

            // 3. 将截图移动到"Work"分类下
            // 注意：在实际应用中，应确保文件路径有效
            if FileManager.default.fileExists(atPath: sampleScreenshotPath) {
                do {
                    let newPath = try organizer.moveScreenshot(
                        from: sampleScreenshotPath, to: "Work")
                    print("截图已移动到: \(newPath)")
                } catch {
                    print("移动文件失败: \(error.localizedDescription)")
                }
            } else {
                print("示例文件不存在，这只是一个演示")
            }
        } catch {
            print("初始化FileOrganizer失败: \(error.localizedDescription)")
        }
    }

    /// 获取默认的截图目录
    private static func getDefaultScreenshotsDirectory() throws -> URL {
        // 在macOS上，默认截图目录通常是'~/Desktop'或自定义位置
        // 这里我们使用一个示例目录
        let picturesDir = try FileManager.default.url(
            for: .picturesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        return picturesDir.appendingPathComponent("Screenshots", isDirectory: true)
    }
}
