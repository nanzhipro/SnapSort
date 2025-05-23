//
//  AISettingsView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// AI设置视图
///
/// 管理人工智能分类功能的配置选项，包括AI模式选择、API密钥管理和连接测试。
/// 支持本地和云端两种AI处理模式，提供安全的API密钥输入和实时连接验证功能。
/// 采用条件化显示设计，根据选择的模式动态展示相关配置选项。
struct AISettingsView: View {

    /// 设置视图模型引用
    @ObservedObject var viewModel: SettingsViewModel

    // MARK: - State

    /// 是否正在测试连接
    @State private var isTestingConnection = false
    /// 连接测试结果消息
    @State private var testResult: String?

    var body: some View {
        Form {
            generalSection

            if viewModel.enableAIClassification {
                modeSelectionSection

                if viewModel.aiClassificationMode == .cloud {
                    cloudSettingsSection
                }
            }
        }
        .padding()
    }
}

// MARK: - View Components

extension AISettingsView {

    /// 通用设置区域
    @ViewBuilder
    fileprivate var generalSection: some View {
        Section {
            Toggle(
                LocalizedStringKey("settings.ai.enabled"),
                isOn: $viewModel.enableAIClassification
            )
        } header: {
            Text(LocalizedStringKey("settings.ai.general"))
        }
    }

    /// 模式选择区域
    @ViewBuilder
    fileprivate var modeSelectionSection: some View {
        Section {
            Picker(
                LocalizedStringKey("settings.ai.mode"),
                selection: $viewModel.aiClassificationMode
            ) {
                ForEach(AIClassificationMode.allCases, id: \.self) { mode in
                    Text(mode.localizedName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text(LocalizedStringKey("settings.ai.classification"))
        } footer: {
            Text(aiModeDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// 云端设置区域
    @ViewBuilder
    fileprivate var cloudSettingsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                apiKeyField
                connectionTestArea
            }
        } header: {
            Text(LocalizedStringKey("settings.ai.cloudSettings"))
        }
    }

    /// API密钥输入字段
    @ViewBuilder
    fileprivate var apiKeyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedStringKey("settings.ai.apiKey"))
                    .font(.headline)
                Spacer()
            }

            SecureField(
                LocalizedStringKey("settings.ai.apiKeyPlaceholder"),
                text: $viewModel.deepSeekAPIKey
            )
            .textFieldStyle(.roundedBorder)

            Text(LocalizedStringKey("settings.ai.apiKeyHelp"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// 连接测试区域
    @ViewBuilder
    fileprivate var connectionTestArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                connectionTestButton

                if isTestingConnection {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.leading, 8)
                }

                Spacer()
            }

            if let result = testResult {
                Text(result)
                    .font(.caption)
                    .foregroundColor(testResultColor)
                    .animation(.easeInOut(duration: 0.3), value: testResult)
            }
        }
    }

    /// 连接测试按钮
    @ViewBuilder
    fileprivate var connectionTestButton: some View {
        Button(LocalizedStringKey("settings.ai.testConnection")) {
            performConnectionTest()
        }
        .disabled(isTestingConnection || !viewModel.validateAPIKey())
        .buttonStyle(.bordered)
    }
}

// MARK: - Computed Properties

extension AISettingsView {

    /// AI模式描述文本
    fileprivate var aiModeDescription: String {
        switch viewModel.aiClassificationMode {
        case .local:
            return NSLocalizedString("settings.ai.localModeDescription", comment: "本地模式说明")
        case .cloud:
            return NSLocalizedString("settings.ai.cloudModeDescription", comment: "云端模式说明")
        }
    }

    /// 测试结果颜色
    fileprivate var testResultColor: Color {
        guard let result = testResult else { return .secondary }
        return result.contains("成功") || result.contains("Success") ? .green : .red
    }
}

// MARK: - Actions

extension AISettingsView {

    /// 执行连接测试
    fileprivate func performConnectionTest() {
        isTestingConnection = true
        testResult = nil

        Task {
            let success = await viewModel.testAPIConnection()

            await MainActor.run {
                isTestingConnection = false
                testResult =
                    success
                    ? NSLocalizedString("settings.ai.connectionSuccess", comment: "连接成功")
                    : NSLocalizedString("settings.ai.connectionFailed", comment: "连接失败")
            }
        }
    }
}

#Preview {
    AISettingsView(viewModel: SettingsViewModel())
        .frame(width: 500, height: 400)
}
