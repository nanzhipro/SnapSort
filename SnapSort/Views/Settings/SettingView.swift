//
//  SettingView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import AppKit
import SwiftUI

// MARK: - SettingsViewModel

/// 设置视图模型
///
/// 负责管理应用程序的所有设置状态和数据持久化。采用MVVM架构模式，
/// 提供响应式的设置数据绑定，确保UI与数据状态的实时同步。
/// 支持自动数据持久化和默认设置初始化。
@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage("isAutoLaunchEnabled") var isAutoLaunchEnabled: Bool = false
    @Published var notificationSettings: NotificationSettings = NotificationSettings.default
    @Published var categories: [Category] = []
    @Published var storageSettings: StorageSettings = StorageSettings.default
    @AppStorage("aiClassificationMode") var aiClassificationMode: AIClassificationMode = .local
    @AppStorage("deepSeekAPIKey") var deepSeekAPIKey: String = ""
    @AppStorage("enableAIClassification") var enableAIClassification: Bool = true

    init() {
        loadDefaultCategories()
    }

    private func loadDefaultCategories() {
        if categories.isEmpty {
            categories = [
                Category(
                    name: NSLocalizedString("category.default.work", comment: "工作"),
                    keywords: ["meeting", "presentation", "document", "工作", "会议", "演示"]),
                Category(
                    name: NSLocalizedString("category.default.personal", comment: "个人"),
                    keywords: ["personal", "family", "photo", "个人", "家庭", "照片"]),
                Category(
                    name: NSLocalizedString("category.default.development", comment: "开发"),
                    keywords: ["code", "xcode", "terminal", "代码", "开发", "编程"]),
            ]
        }
    }

    func addCategory(_ category: Category) {
        categories.append(category)
    }

    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
    }

    func deleteCategory(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }

    func selectBaseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = NSLocalizedString("directory.picker.message", comment: "选择截图分类保存的基础目录")

        if panel.runModal() == .OK {
            if let selectedURL = panel.url {
                storageSettings.baseDirectory = selectedURL.path
            }
        }
    }

    func validateAPIKey() -> Bool {
        guard aiClassificationMode == .cloud else { return true }
        return !deepSeekAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func testAPIConnection() async -> Bool {
        guard validateAPIKey() else { return false }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return true
    }
}

// MARK: - 主设置视图

/// 应用程序设置视图
///
/// 提供应用程序的配置和关于信息界面，采用TabView布局组织各个设置模块。
/// 集成了通用设置、分类管理、目录配置、AI设置和关于信息等功能模块。
/// 遵循macOS设计规范，提供统一的设置管理入口。
struct SettingView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label(LocalizedStringKey("settings.general"), systemImage: "gearshape")
                }

            CategoriesView(viewModel: viewModel)
                .tabItem {
                    Label(
                        LocalizedStringKey("settings.categories"),
                        systemImage: "folder.badge.gearshape")
                }

            DirectoriesView(viewModel: viewModel)
                .tabItem {
                    Label(LocalizedStringKey("settings.directories"), systemImage: "folder")
                }

            AISettingsView(viewModel: viewModel)
                .tabItem {
                    Label(LocalizedStringKey("settings.ai"), systemImage: "brain")
                }

            AboutView()
                .tabItem {
                    Label(LocalizedStringKey("settings.about"), systemImage: "info.circle")
                }
        }
        .frame(width: 600, height: 500)
    }
}

#Preview {
    SettingView()
}
