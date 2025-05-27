//
//  SettingView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import AppKit
import SwiftUI

/// 应用程序设置视图
///
/// 提供应用程序的配置和关于信息界面，采用标准macOS设置页面风格。
/// 使用TabView组织各个设置模块，遵循Apple HIG设计规范。
/// 提供简洁清晰的设置管理入口。
struct SettingView: View {

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label(LocalizedStringKey("settings.general"), systemImage: "gearshape")
                }
                .tag(0)

            CategoriesView()
                .tabItem {
                    Label(
                        LocalizedStringKey("settings.categories"),
                        systemImage: "folder.badge.gearshape")
                }
                .tag(1)

            AISettingsView()
                .tabItem {
                    Label(LocalizedStringKey("settings.ai"), systemImage: "brain.head.profile")
                }
                .tag(2)

            AboutView()
                .tabItem {
                    Label(LocalizedStringKey("settings.about"), systemImage: "info.circle")
                }
                .tag(3)
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    SettingView()
}
