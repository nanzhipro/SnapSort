//
//  SettingView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import AppKit
import SwiftUI

/// Application Settings View
///
/// Provides configuration and about information interface for the application, using standard macOS settings page style.
/// Organizes each settings module using TabView, following Apple HIG design guidelines.
/// Provides a clean and clear entry point for settings management.
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
                    Label(LocalizedStringKey("settings.ai"), systemImage: "sparkles")
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
