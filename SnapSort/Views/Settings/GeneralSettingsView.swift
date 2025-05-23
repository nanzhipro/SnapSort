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
/// 采用Form布局确保设置项的清晰展示，支持条件化显示详细通知选项。
/// 遵循Apple HIG设计规范，提供原生macOS用户体验。
struct GeneralSettingsView: View {

    /// 设置视图模型引用
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            startupSection
            notificationSection
        }
        .padding()
    }
}

// MARK: - View Components

extension GeneralSettingsView {

    /// 启动选项设置区域
    @ViewBuilder
    fileprivate var startupSection: some View {
        Section {
            Toggle(
                LocalizedStringKey("settings.general.launchAtStartup"),
                isOn: $viewModel.isAutoLaunchEnabled
            )
        } header: {
            Text(LocalizedStringKey("settings.general.startup"))
        }
    }

    /// 通知设置区域
    @ViewBuilder
    fileprivate var notificationSection: some View {
        Section {
            Toggle(
                LocalizedStringKey("settings.general.showNotifications"),
                isOn: $viewModel.notificationSettings.isEnabled
            )

            if viewModel.notificationSettings.isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(
                        LocalizedStringKey("settings.general.showClassificationResult"),
                        isOn: $viewModel.notificationSettings.showClassificationResult
                    )

                    Toggle(
                        LocalizedStringKey("settings.general.showErrors"),
                        isOn: $viewModel.notificationSettings.showErrorMessages
                    )

                    Toggle(
                        LocalizedStringKey("settings.general.soundEnabled"),
                        isOn: $viewModel.notificationSettings.soundEnabled
                    )
                }
                .animation(
                    .easeInOut(duration: 0.2), value: viewModel.notificationSettings.isEnabled)
            }
        } header: {
            Text(LocalizedStringKey("settings.general.notifications"))
        }
    }
}

#Preview {
    GeneralSettingsView(viewModel: SettingsViewModel())
        .frame(width: 400, height: 300)
}
