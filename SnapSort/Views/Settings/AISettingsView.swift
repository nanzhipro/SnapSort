//
//  AISettingsView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// AI Settings View
///
/// Manages configuration options for AI classification functionality, including API key management.
/// Provides cloud-based AI processing mode, supporting secure API key input and binary storage.
/// Uses standard macOS settings page style with Form layout to display relevant configuration options.
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

    // MARK: - API Key Management

    /// Validate and save API key
    private func validateAndSaveApiKey(_ key: String) {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)

        // Basic validation: check if it's a valid API key format
        isApiKeyValid = isValidApiKeyFormat(trimmedKey)

        if isApiKeyValid && !trimmedKey.isEmpty {
            saveApiKeyToUserDefaults(trimmedKey)
        } else if trimmedKey.isEmpty {
            clearApiKeyFromUserDefaults()
        }
    }

    /// Validate API key format
    private func isValidApiKeyFormat(_ key: String) -> Bool {
        // DeepSeek API keys typically start with "sk-" and are between 40-60 characters long
        return key.hasPrefix("sk-") && key.count >= 20 && key.count <= 100
    }

    /// Save API key in binary form to UserDefaults
    private func saveApiKeyToUserDefaults(_ key: String) {
        guard let keyData = key.data(using: .utf8) else { return }
        UserDefaults.standard.set(keyData, forKey: "ai_api_key_data")
    }

    /// Load API key from UserDefaults
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

    /// Clear API key
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
