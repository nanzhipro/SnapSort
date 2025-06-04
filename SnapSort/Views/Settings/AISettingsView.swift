//
//  AISettingsView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// AI设置视图
///
/// 管理人工智能分类功能的配置选项，包括API密钥管理。
/// 提供云端AI处理模式，支持安全的API密钥输入和二进制存储功能。
/// 采用标准macOS设置页面风格，使用Form布局展示相关配置选项。
struct AISettingsView: View {

    @AppStorage("enableAIClassification") private var enableAIClassification: Bool = true

    @State private var apiKey: String = ""
    @State private var isApiKeyValid: Bool = false

    var body: some View {
        Form {
            Section(LocalizedStringKey("settings.ai.section")) {
                Toggle(LocalizedStringKey("settings.ai.enabled"), isOn: $enableAIClassification)
                    .help(LocalizedStringKey("settings.ai.enabledHelp"))

                if enableAIClassification {
                    Text(String(localized: "settings.ai.modeCloudDesc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if enableAIClassification {
                Section(LocalizedStringKey("settings.ai.cloudSettings")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(LocalizedStringKey("settings.ai.apiKey"))
                            Spacer()
                            if isApiKeyValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else if !apiKey.isEmpty {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }

                        SecureField(
                            LocalizedStringKey("settings.ai.apiKeyPlaceholder"), text: $apiKey
                        )
                        .textFieldStyle(.roundedBorder)
                        .help(LocalizedStringKey("settings.ai.apiKeyHelp"))
                        .onChange(of: apiKey) { _, newValue in
                            validateAndSaveApiKey(newValue)
                        }

                        if !apiKey.isEmpty && !isApiKeyValid {
                            Text(LocalizedStringKey("settings.ai.apiKeyInvalid"))
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    HStack {
                        Button(LocalizedStringKey("settings.ai.clearApiKey")) {
                            clearApiKey()
                        }
                        .disabled(apiKey.isEmpty)

                        Spacer()

                        Text(LocalizedStringKey("settings.ai.apiKeySecureStorage"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadApiKey()
        }
    }

    // MARK: - API密钥管理

    /// 验证并保存API密钥
    private func validateAndSaveApiKey(_ key: String) {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)

        // 基本验证：检查是否为有效的API密钥格式
        isApiKeyValid = isValidApiKeyFormat(trimmedKey)

        if isApiKeyValid && !trimmedKey.isEmpty {
            saveApiKeyToUserDefaults(trimmedKey)
        } else if trimmedKey.isEmpty {
            clearApiKeyFromUserDefaults()
        }
    }

    /// 验证API密钥格式
    private func isValidApiKeyFormat(_ key: String) -> Bool {
        // DeepSeek API密钥通常以"sk-"开头，长度在40-60字符之间
        return key.hasPrefix("sk-") && key.count >= 20 && key.count <= 100
    }

    /// 将API密钥以二进制形式保存到UserDefaults
    private func saveApiKeyToUserDefaults(_ key: String) {
        guard let keyData = key.data(using: .utf8) else { return }
        UserDefaults.standard.set(keyData, forKey: "ai_api_key_data")
    }

    /// 从UserDefaults加载API密钥
    private func loadApiKey() {
        guard let keyData = UserDefaults.standard.data(forKey: "ai_api_key_data"),
            let key = String(data: keyData, encoding: .utf8)
        else {
            apiKey = ""
            isApiKeyValid = false
            return
        }

        apiKey = key
        isApiKeyValid = isValidApiKeyFormat(key)
    }

    /// 清除API密钥
    private func clearApiKey() {
        apiKey = ""
        isApiKeyValid = false
        clearApiKeyFromUserDefaults()
    }

    /// 从UserDefaults清除API密钥
    private func clearApiKeyFromUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "ai_api_key_data")
    }
}

#Preview {
    AISettingsView()
        .frame(width: 500, height: 400)
}
