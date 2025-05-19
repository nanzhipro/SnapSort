//
//  SnapSortApp.swift
//  SnapSort
//
//  Created by 南朋友 on 2025/5/7.
//

import SwiftUI

@main
struct SnapSortApp: App {
    // 使用AppDelegate管理应用生命周期事件
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            // 使用主界面ContentView
            ContentView()
        }
    }
}
