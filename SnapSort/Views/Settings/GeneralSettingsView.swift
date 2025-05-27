//
//  GeneralSettingsView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import LaunchAtLogin
import SwiftUI

/// 通用设置视图
///
/// 提供应用程序的基本设置选项，包括启动行为、通知配置和存储位置设置。
/// 采用标准macOS设置页面风格，使用Form布局确保设置项的清晰展示。
/// 遵循Apple HIG设计规范，提供原生macOS用户体验。
struct GeneralSettingsView: View {

    @AppStorage("showNotifications") private var showNotifications: Bool = true
    @AppStorage("screenshotDirectory") private var screenshotDirectory: String = ""

    @State private var isDirectorySelected: Bool = false
    @State private var notificationManager = NotificationManager()

    var body: some View {
        Form {
            Section(LocalizedStringKey("settings.general.startup")) {
                LaunchAtLogin.Toggle(LocalizedStringKey("settings.general.launchAtStartup"))
            }

            Section(LocalizedStringKey("settings.general.notifications")) {
                Toggle(
                    LocalizedStringKey("settings.general.showNotifications"),
                    isOn: $showNotifications
                )
                .onChange(of: showNotifications) { _, newValue in
                    handleNotificationSettingChange(newValue)
                }
            }

            Section(LocalizedStringKey("settings.general.storage")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(LocalizedStringKey("settings.general.currentDirectory"))
                        Spacer()
                        Text(
                            isDirectorySelected
                                ? String(localized: "settings.general.directorySet")
                                : String(localized: "settings.general.notSelected")
                        )
                        .foregroundColor(isDirectorySelected ? .green : .secondary)
                    }

                    if !screenshotDirectory.isEmpty {
                        Text(screenshotDirectory)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                }

                HStack {
                    Button(LocalizedStringKey("settings.general.selectDirectory")) {
                        selectDirectory()
                    }

                    if isDirectorySelected {
                        Button(LocalizedStringKey("settings.general.resetToDefault")) {
                            resetToDefaultLocation()
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadCurrentScreenshotLocation()
        }
    }

    // MARK: - Private Methods

    /// 处理通知设置变化
    private func handleNotificationSettingChange(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await notificationManager.requestAuthorization()
                if !granted {
                    // 如果用户拒绝授权，可以显示提示信息
                    await MainActor.run {
                        showNotifications = false
                    }
                }
            }
        }
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = String(localized: "directory.picker.message")

        if panel.runModal() == .OK {
            if let selectedURL = panel.url {
                setScreenshotDirectory(selectedURL.path)
            }
        }
    }

    private func resetToDefaultLocation() {
        Task {
            // 删除自定义设置，恢复系统默认
            _ = try? await executeShellCommand("defaults delete com.apple.screencapture location")
            _ = try? await executeShellCommand("killall SystemUIServer")

            await MainActor.run {
                screenshotDirectory = ""
                isDirectorySelected = false
            }
        }
    }

    private func setScreenshotDirectory(_ path: String) {
        Task {
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
            } catch {
                print("Failed to set screenshot location: \(error)")
            }
        }
    }

    private func loadCurrentScreenshotLocation() {
        Task {
            do {
                let location = try await executeShellCommand(
                    "defaults read com.apple.screencapture location")
                await MainActor.run {
                    if location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        screenshotDirectory = ""
                        isDirectorySelected = false
                    } else {
                        screenshotDirectory = location.trimmingCharacters(
                            in: .whitespacesAndNewlines)
                        isDirectorySelected = true
                    }
                }
            } catch {
                await MainActor.run {
                    screenshotDirectory = ""
                    isDirectorySelected = false
                }
            }
        }
    }

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
                    continuation.resume(
                        throwing: NSError(
                            domain: "ShellCommand", code: Int(process.terminationStatus)))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 500, height: 400)
}
