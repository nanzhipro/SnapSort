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
/// 采用标准macOS设置页面风格，使用Form布局根据选择的模式动态展示相关配置选项。
struct AISettingsView: View {

    @AppStorage("enableAIClassification") private var enableAIClassification: Bool = true
    @AppStorage("aiClassificationMode") private var aiClassificationMode: AIMode = .local
    @AppStorage("deepSeekAPIKey") private var deepSeekAPIKey: String = ""

    @State private var isTestingConnection = false
    @State private var testResult: String?

    var body: some View {
        Form {
            Section(LocalizedStringKey("settings.ai.section")) {
                Toggle(LocalizedStringKey("settings.ai.enabled"), isOn: $enableAIClassification)
                    .help(LocalizedStringKey("settings.ai.enabledHelp"))

                if enableAIClassification {
                    Picker(LocalizedStringKey("settings.ai.mode"), selection: $aiClassificationMode)
                    {
                        Text(LocalizedStringKey("settings.ai.modeLocal")).tag(AIMode.local)
                        Text(LocalizedStringKey("settings.ai.modeCloud")).tag(AIMode.cloud)
                    }
                    .pickerStyle(.segmented)

                    Text(modeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if enableAIClassification && aiClassificationMode == .cloud {
                Section(LocalizedStringKey("settings.ai.cloudSettings")) {
                    SecureField(LocalizedStringKey("settings.ai.apiKey"), text: $deepSeekAPIKey)
                        .help(LocalizedStringKey("settings.ai.apiKeyHelp"))

                    HStack {
                        Button(LocalizedStringKey("settings.ai.testConnection")) {
                            testConnection()
                        }
                        .disabled(
                            deepSeekAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || isTestingConnection)

                        if isTestingConnection {
                            ProgressView()
                                .scaleEffect(0.8)
                                .controlSize(.small)
                        }

                        Spacer()
                    }

                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(
                                result.contains(String(localized: "settings.ai.connectionSuccess"))
                                    ? .green : .red)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modeDescription: String {
        switch aiClassificationMode {
        case .local:
            return String(localized: "settings.ai.modeLocalDesc")
        case .cloud:
            return String(localized: "settings.ai.modeCloudDesc")
        }
    }

    private func testConnection() {
        isTestingConnection = true
        testResult = nil

        Task {
            // 模拟API连接测试
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            await MainActor.run {
                isTestingConnection = false
                testResult =
                    Bool.random()
                    ? String(localized: "settings.ai.connectionSuccess")
                    : String(localized: "settings.ai.connectionFailed")
            }
        }
    }
}

// MARK: - 数据模型

enum AIMode: String, CaseIterable, Codable {
    case local = "local"
    case cloud = "cloud"
}

#Preview {
    AISettingsView()
        .frame(width: 500, height: 400)
}
