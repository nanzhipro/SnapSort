//
//  SnapSortApp.swift
//  SnapSort
//
//  Created by 南朋友 on 2025/5/7.
//

import AppKit
import SwiftUI

@main
struct SnapSortApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        // 设置窗口 - 使用 Settings 而不是 Window
        Settings {
            SettingView()
        }

        MenuBarExtra {
            VStack(spacing: 8) {
                // 使用 SettingsLink 而不是自定义 Button
                SettingsLink {
                    Text(LocalizedStringKey("menu.settings"))
                }

                Divider()

                Button(LocalizedStringKey("menu.quit")) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        } label: {
            Label("SnapSort", systemImage: "photo.on.rectangle.angled")
        }
        .menuBarExtraStyle(.menu)
    }
}
