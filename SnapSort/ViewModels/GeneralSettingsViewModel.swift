//
//  GeneralSettingsViewModel.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Combine
import Foundation
import os.log

/// 通用设置视图模型
///
/// 管理应用程序的基本设置，包括通知权限、系统截屏目录配置等功能。
/// 遵循MVVM架构模式，提供响应式的设置状态管理和业务逻辑处理。
/// 通过Combine框架实现状态变化的响应式更新。
@MainActor
final class GeneralSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 是否显示通知
    @Published var showNotifications: Bool = true {
        didSet {
            handleNotificationSettingChange()
        }
    }

    /// 当前截屏存储目录
    @Published var screenshotDirectory: String = ""

    /// 目录选择状态
    @Published var isDirectorySelected: Bool = false

    /// 通知权限状态
    @Published var notificationAuthorizationStatus: String = "未知"

    // MARK: - Dependencies

    private let notificationManager: NotificationManagerProtocol
    private let logger = Logger(
        subsystem: "com.snapsort.settings", category: "GeneralSettingsViewModel")

    // MARK: - Initialization

    /// 初始化视图模型
    /// - Parameter notificationManager: 通知管理器实例
    init(notificationManager: NotificationManagerProtocol = NotificationManager()) {
        self.notificationManager = notificationManager
        loadInitialSettings()
    }

    // MARK: - Public Methods

    /// 选择截屏存储目录
    /// - Parameter directoryURL: 用户选择的目录URL
    func selectScreenshotDirectory(_ directoryURL: URL) {
        Task {
            await setSystemScreenshotLocation(directoryURL.path)
        }
    }

    /// 刷新当前设置状态
    func refreshSettings() {
        Task {
            await loadCurrentScreenshotLocation()
            await checkNotificationAuthorization()
        }
    }

    // MARK: - Private Methods

    /// 加载初始设置
    private func loadInitialSettings() {
        // 从UserDefaults加载通知设置
        showNotifications = UserDefaults.standard.bool(forKey: "showNotifications")

        Task {
            await loadCurrentScreenshotLocation()
            await checkNotificationAuthorization()
        }
    }

    /// 处理通知设置变化
    private func handleNotificationSettingChange() {
        UserDefaults.standard.set(showNotifications, forKey: "showNotifications")

        if showNotifications {
            Task {
                let granted = await notificationManager.requestAuthorization()
                await MainActor.run {
                    notificationAuthorizationStatus = granted ? "已授权" : "被拒绝"
                }
            }
        } else {
            notificationAuthorizationStatus = "已禁用"
        }

        logger.info("Notification setting changed to: \(self.showNotifications)")
    }

    /// 检查通知授权状态
    private func checkNotificationAuthorization() async {
        // 这里可以添加检查当前通知权限状态的逻辑
        // 由于NotificationManager当前没有提供状态查询方法，暂时使用设置值
        await MainActor.run {
            notificationAuthorizationStatus = self.showNotifications ? "已启用" : "已禁用"
        }
    }

    /// 加载当前系统截屏存储位置
    private func loadCurrentScreenshotLocation() async {
        do {
            let location = try await executeShellCommand(
                "defaults read com.apple.screencapture location")
            await MainActor.run {
                if location.isEmpty {
                    // 默认桌面路径
                    screenshotDirectory = NSHomeDirectory() + "/Desktop"
                    isDirectorySelected = false
                } else {
                    screenshotDirectory = location.trimmingCharacters(in: .whitespacesAndNewlines)
                    isDirectorySelected = true
                }
            }
        } catch {
            logger.error("Failed to read screenshot location: \(error.localizedDescription)")
            await MainActor.run {
                screenshotDirectory = NSHomeDirectory() + "/Desktop"
                isDirectorySelected = false
            }
        }
    }

    /// 设置系统截屏存储位置
    /// - Parameter path: 新的存储路径
    private func setSystemScreenshotLocation(_ path: String) async {
        do {
            // 设置新的截屏位置
            _ = try await executeShellCommand(
                "defaults write com.apple.screencapture location '\(path)'")

            // 重启SystemUIServer使设置生效
            _ = try await executeShellCommand("killall SystemUIServer")

            await MainActor.run {
                screenshotDirectory = path
                isDirectorySelected = true
            }

            logger.info("Screenshot location updated to: \(path)")
        } catch {
            logger.error("Failed to set screenshot location: \(error.localizedDescription)")
        }
    }

    /// 执行Shell命令
    /// - Parameter command: 要执行的命令
    /// - Returns: 命令输出结果
    private func executeShellCommand(_ command: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.standardOutput = pipe
            process.standardError = pipe
            process.arguments = ["-c", command]
            process.executableURL = URL(fileURLWithPath: "/bin/sh")

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: SettingsError.commandFailed(output))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Error Types

/// 设置相关错误类型
enum SettingsError: LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let output):
            return "命令执行失败: \(output)"
        }
    }
}
