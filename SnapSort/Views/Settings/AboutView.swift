//
//  AboutView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// 关于视图
///
/// 展示应用程序的基本信息，包括应用名称、版本号、功能描述和版权信息。
/// 采用居中布局设计，提供清晰的信息层次结构和专业的视觉呈现。
/// 遵循Apple设计规范，确保与系统设置界面保持一致的用户体验。
struct AboutView: View {

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                appIconSection
                appInfoSection
                descriptionSection
                copyrightSection

                Spacer(minLength: 20)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - View Components

extension AboutView {

    /// 应用图标区域
    @ViewBuilder
    fileprivate var appIconSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }

    /// 应用信息区域
    @ViewBuilder
    fileprivate var appInfoSection: some View {
        VStack(spacing: 8) {
            Text("SnapSort")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(LocalizedStringKey("about.version"))
                .font(.title2)
                .foregroundColor(.secondary)

            Text(versionNumber)
                .font(.caption)
                .foregroundColor(Color.secondary.opacity(0.8))
                .padding(.top, 4)
        }
    }

    /// 描述信息区域
    @ViewBuilder
    fileprivate var descriptionSection: some View {
        VStack(spacing: 12) {
            Text(LocalizedStringKey("about.description"))
                .font(.headline)
                .foregroundColor(.primary)

            Text(LocalizedStringKey("about.features"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
    }

    /// 版权信息区域
    @ViewBuilder
    fileprivate var copyrightSection: some View {
        VStack(spacing: 8) {
            Text(LocalizedStringKey("about.copyright"))
                .font(.caption)
                .foregroundColor(.secondary)

            Text(LocalizedStringKey("about.rights"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Computed Properties

extension AboutView {

    /// 版本号信息
    fileprivate var versionNumber: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
}

#Preview {
    AboutView()
        .frame(width: 500, height: 400)
}
