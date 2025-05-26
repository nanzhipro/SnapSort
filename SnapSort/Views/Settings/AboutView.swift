//
//  AboutView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// 关于视图
///
/// 显示应用程序的版本信息、开发者信息和相关链接。
/// 采用标准macOS设置页面风格，提供清晰的应用信息展示。
struct AboutView: View {

    private let appVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)

                    Text("SnapSort")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("截图智能整理工具")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section("版本信息") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("构建版本")
                    Spacer()
                    Text(buildNumber)
                        .foregroundColor(.secondary)
                }
            }

            Section("开发者") {
                HStack {
                    Text("开发者")
                    Spacer()
                    Text("CursorAI")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("版权")
                    Spacer()
                    Text("© 2025 SnapSort")
                        .foregroundColor(.secondary)
                }
            }

            Section("支持") {
                Button("访问官网") {
                    // 打开官网链接
                }

                Button("反馈问题") {
                    // 打开反馈页面
                }

                Button("用户手册") {
                    // 打开用户手册
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AboutView()
        .frame(width: 500, height: 400)
}
