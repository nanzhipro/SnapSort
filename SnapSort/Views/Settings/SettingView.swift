//
//  SettingView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// 应用程序设置视图
/// 提供应用程序的配置和关于信息界面
struct SettingView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label(LocalizedStringKey("settings.general"), systemImage: "gearshape")
                }

            AboutView()
                .tabItem {
                    Label(LocalizedStringKey("settings.about"), systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

/// 通用设置视图
private struct GeneralSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(LocalizedStringKey("settings.general.title"))
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("settings.general.preferences"))
                    .font(.headline)

                // 这里可以添加具体的设置选项
                HStack {
                    Text(LocalizedStringKey("settings.general.launchAtStartup"))
                    Spacer()
                    Toggle("", isOn: .constant(false))
                }

                HStack {
                    Text(LocalizedStringKey("settings.general.showNotifications"))
                    Spacer()
                    Toggle("", isOn: .constant(true))
                }
            }

            Spacer()
        }
        .padding()
    }
}

/// 关于视图
private struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "app.gift")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("SnapSort")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(LocalizedStringKey("about.version"))
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 4) {
                Text(LocalizedStringKey("about.description"))
                    .font(.headline)

                Text(LocalizedStringKey("about.features"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                Text(LocalizedStringKey("about.copyright"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(LocalizedStringKey("about.rights"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    SettingView()
}
