//
//  CategoriesView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Foundation
import SwiftUI

/// 分类管理视图
///
/// 提供截图分类的完整管理功能，包括分类列表展示、新增、编辑和删除操作。
/// 采用标准macOS设置页面风格，使用Form布局展示所有分类。
/// 提供简洁清晰的分类管理界面。
struct CategoriesView: View {

    @State private var categories: [CategoryItem] = [
        CategoryItem(
            name: String(localized: "category.default.work"),
            keywords: ["meeting", "presentation", "document"]),
        CategoryItem(
            name: String(localized: "category.default.personal"),
            keywords: ["personal", "family", "photo"]),
        CategoryItem(
            name: String(localized: "category.default.development"),
            keywords: ["code", "xcode", "terminal"]),
    ]
    @State private var showingAddSheet = false
    @State private var editingCategory: CategoryItem?

    var body: some View {
        Form {
            Section(LocalizedStringKey("settings.categories.management")) {
                List {
                    ForEach(categories) { category in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.name)
                                    .font(.headline)

                                if !category.keywords.isEmpty {
                                    Text(category.keywords.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button(LocalizedStringKey("common.edit")) {
                                editingCategory = category
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteCategories)
                }
                .frame(minHeight: 200)

                Button(LocalizedStringKey("settings.categories.add")) {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingAddSheet) {
            CategoryEditSheet(category: nil) { newCategory in
                categories.append(newCategory)
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditSheet(category: category) { updatedCategory in
                if let index = categories.firstIndex(where: { $0.id == category.id }) {
                    categories[index] = updatedCategory
                }
            }
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }
}

// MARK: - 数据模型
// CategoryItem 定义在 Models/CategoryModels.swift 中

// MARK: - 编辑表单

struct CategoryEditSheet: View {
    let category: CategoryItem?
    let onSave: (CategoryItem) -> Void

    @State private var name: String = ""
    @State private var keywordsText: String = ""
    @Environment(\.dismiss) private var dismiss

    private var isEditing: Bool { category != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizedStringKey("settings.categories.basicInfo")) {
                    TextField(LocalizedStringKey("settings.categories.name"), text: $name)
                }

                Section(LocalizedStringKey("settings.categories.keywords")) {
                    TextField(
                        LocalizedStringKey("settings.categories.keywordsPlaceholder"),
                        text: $keywordsText, axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(
                isEditing
                    ? LocalizedStringKey("settings.categories.edit")
                    : LocalizedStringKey("settings.categories.add")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("common.save")) {
                        let keywords =
                            keywordsText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        let newCategory = CategoryItem(name: name, keywords: keywords)
                        onSave(newCategory)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
        .onAppear {
            if let category = category {
                name = category.name
                keywordsText = category.keywords.joined(separator: ", ")
            }
        }
    }
}

#Preview {
    CategoriesView()
        .frame(width: 500, height: 400)
}
