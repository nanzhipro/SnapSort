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
        // 主窗口组 - 在LSUIElement模式下隐藏
        WindowGroup("Main") {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 0, height: 0)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))

        // 设置窗口组 - 用于LSUIElement模式下的设置显示
        WindowGroup("Settings", id: "settings") {
            SettingView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 500)
        .windowToolbarStyle(.unifiedCompact(showsTitle: true))

        // 菜单栏额外项
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            Label("SnapSort", systemImage: "photo.on.rectangle.angled")
        }
        .menuBarExtraStyle(.menu)
    }
}

/// 菜单栏内容视图
///
/// 提供菜单栏下拉菜单的内容，包括设置和退出选项
struct MenuBarContentView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 8) {
            Button(LocalizedStringKey("menu.settings")) {
                openSettingsWindow()
            }
            .buttonStyle(.plain)

            Divider()

            Button(LocalizedStringKey("menu.quit")) {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    /// 打开设置窗口
    private func openSettingsWindow() {
        // 激活应用程序以确保窗口能够显示
        NSApplication.shared.activate(ignoringOtherApps: true)

        // 使用SwiftUI的openWindow环境值打开设置窗口
        openWindow(id: "settings")
    }
}
