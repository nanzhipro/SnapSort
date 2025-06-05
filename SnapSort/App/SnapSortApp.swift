//
//  SnapSortApp.swift
//  SnapSort
//
//  Created by CursorAI on 2025/5/7.
//

import AppKit
import SwiftUI

@main
struct SnapSortApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Window group - used for settings display in LSUIElement mode
        WindowGroup("Settings", id: "settings") {
            SettingView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 500)
        .windowToolbarStyle(.unifiedCompact(showsTitle: true))
        .defaultLaunchBehavior(.suppressed)

        // Menu bar extra item
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            Label("SnapSort", systemImage: "photo.on.rectangle.angled")
        }
        .menuBarExtraStyle(.menu)
    }
}

/// Menu Bar Content View
///
/// Provides content for the menu bar dropdown, including settings and quit options
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

    /// Opens the settings window
    private func openSettingsWindow() {
        // Activate the application to ensure window visibility
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Use SwiftUI's openWindow environment value to open settings window
        openWindow(id: "settings")
    }
}
