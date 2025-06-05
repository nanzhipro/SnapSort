//
//  AppDelegate.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import AppKit
import Foundation
import os.log

/// Application Delegate
///
/// Handles application lifecycle events and system-level interactions.
/// Manages menu bar icon, global shortcuts, and application state.
class AppDelegate: NSObject, NSApplicationDelegate {
    /// System logger
    private let logger = Logger(subsystem: "com.snapsort.app", category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application did finish launching")

        // In actual implementation, you need to call your ServiceManager
        // Example: ServiceManager.shared.startServices()
        // Below is an example structure using Task for async execution
        Task {
            do {
                logger.info("Starting services...")

                // Call the startServices() method of ServiceManager (which will automatically start ScreenshotMonitor)
                try await ServiceManager.shared.startServices()

                logger.info("Services started successfully")
            } catch {
                logger.error("Failed to start services: \(error.localizedDescription)")
                // Display error message
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "服务启动失败"
                    alert.informativeText = "无法启动应用服务：\(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application will terminate")

        // In actual implementation, you need to stop ServiceManager
        // Example: ServiceManager.shared.stopServices()
        Task {
            logger.info("Stopping services...")

            // Call the stopServices() method of ServiceManager
            await ServiceManager.shared.stopServices()

            logger.info("Services stopped successfully")
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        // Handle application reopen event
        return true
    }
}
