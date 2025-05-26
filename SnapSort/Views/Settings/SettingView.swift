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
                    Label("通用", systemImage: "gearshape")
                }
                .tag(0)

            CategoriesView()
                .tabItem {
                    Label("分类", systemImage: "folder.badge.gearshape")
                }
                .tag(1)

            DirectoriesView()
                .tabItem {
                    Label("目录", systemImage: "folder")
                }
                .tag(2)

            AISettingsView()
                .tabItem {
                    Label("AI设置", systemImage: "brain.head.profile")
                }
                .tag(3)

            AboutView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
                .tag(4)
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    SettingView()
}
