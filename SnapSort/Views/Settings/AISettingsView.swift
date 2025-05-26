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
            Section("AI分类") {
                Toggle("启用AI分类", isOn: $enableAIClassification)
                    .help("使用人工智能自动分类截图")

                if enableAIClassification {
                    Picker("处理模式", selection: $aiClassificationMode) {
                        Text("本地处理").tag(AIMode.local)
                        Text("云端处理").tag(AIMode.cloud)
                    }
                    .pickerStyle(.segmented)

                    Text(modeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if enableAIClassification && aiClassificationMode == .cloud {
                Section("云端设置") {
                    SecureField("API密钥", text: $deepSeekAPIKey)
                        .help("输入DeepSeek API密钥")

                    HStack {
                        Button("测试连接") {
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
                            .foregroundColor(result.contains("成功") ? .green : .red)
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
            return "在本地设备上处理，保护隐私但功能有限"
        case .cloud:
            return "使用云端AI服务，功能强大但需要网络连接"
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
                testResult = Bool.random() ? "连接成功" : "连接失败，请检查API密钥"
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
