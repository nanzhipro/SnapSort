//
//  AppDelegate.swift
//  SnapSort
//
//  Created by CursorAI on 2024-05-16.
//

import Cocoa
import SwiftUI
import os.log

/// 应用程序委托
/// 负责应用程序生命周期事件的处理，包括启动和终止时的服务管理。
class AppDelegate: NSObject, NSApplicationDelegate {
    /// 系统日志记录器
    private let logger = Logger(subsystem: "com.snapsort.app", category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application did finish launching")

        // 在实际实现中，您需要调用您的ServiceManager
        // 例如：ServiceManager.shared.startServices()
        // 下面是使用Task异步执行的示例结构
        Task {
            do {
                logger.info("Starting services...")

                // 调用服务管理器的 startServices() 方法（将内部自动启动 ScreenshotMonitor）
                try await ServiceManager.shared.startServices()

                logger.info("Services started successfully")
            } catch {
                logger.error("Failed to start services: \(error.localizedDescription)")
                // 显示错误提示
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

        // 在实际实现中，您需要停止ServiceManager
        // 例如：ServiceManager.shared.stopServices()
        Task {
            logger.info("Stopping services...")

            // 调用服务管理器的 stopServices() 方法
            await ServiceManager.shared.stopServices()

            logger.info("Services stopped successfully")
        }
    }
}
