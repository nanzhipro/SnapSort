//
//  GeneralSettingsView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// 通用设置视图
///
/// 提供应用程序的基本设置选项，包括启动行为和通知配置。
/// 采用标准macOS设置页面风格，使用Form布局确保设置项的清晰展示。
/// 遵循Apple HIG设计规范，提供原生macOS用户体验。
struct GeneralSettingsView: View {

    @AppStorage("isAutoLaunchEnabled") private var isAutoLaunchEnabled: Bool = false
    @AppStorage("showNotifications") private var showNotifications: Bool = true
    @AppStorage("showClassificationResult") private var showClassificationResult: Bool = true
    @AppStorage("showErrorMessages") private var showErrorMessages: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = false

    var body: some View {
        Form {
            Section("启动") {
                Toggle("开机时自动启动", isOn: $isAutoLaunchEnabled)
            }

            Section("通知") {
                Toggle("显示通知", isOn: $showNotifications)

                if showNotifications {
                    Toggle("显示分类结果", isOn: $showClassificationResult)
                        .disabled(!showNotifications)

                    Toggle("显示错误消息", isOn: $showErrorMessages)
                        .disabled(!showNotifications)

                    Toggle("启用声音", isOn: $soundEnabled)
                        .disabled(!showNotifications)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 500, height: 400)
}
