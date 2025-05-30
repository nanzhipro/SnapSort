//
//  CategoriesView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Foundation
import SwiftUI

// MARK: - 导入依赖模块

// 导入模型和视图模型
// CategoryItem 定义在 Models/CategoryModels.swift
// CategoriesViewModel 定义在 ViewModels/CategoriesViewModel.swift

/// 分类管理视图
///
/// 提供截图分类的完整管理功能，包括分类列表展示、新增、编辑和删除操作。
/// 采用标准macOS设置页面风格，使用Form布局展示所有分类。
/// 提供简洁清晰的分类管理界面，支持直观的编辑和删除操作。
/// 遵循 MVVM 架构，通过 CategoriesViewModel 进行数据管理。
struct CategoriesView: View {

    // MARK: - Properties

    /// 分类管理视图模型
    @StateObject private var viewModel = CategoriesViewModel()

    /// 是否显示添加分类表单
    @State private var showingAddSheet = false

    /// 正在编辑的分类
    @State private var editingCategory: CategoryItem?

    /// 是否显示删除确认对话框
    @State private var showingDeleteAlert = false

    /// 待删除的分类
    @State private var categoryToDelete: CategoryItem?

    // MARK: - Body

    var body: some View {
        Form {
            Section(LocalizedStringKey("settings.categories.section")) {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.categories.isEmpty {
                    emptyStateView
                } else {
                    categoriesListView
                }

                addCategoryButton
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.loadCategories()
        }
        .sheet(isPresented: $showingAddSheet) {
            CategoryEditSheet(category: nil) { newCategory in
                viewModel.addCategory(newCategory)
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditSheet(category: category) { updatedCategory in
                viewModel.updateCategory(categoryId: category.id, updatedCategory: updatedCategory)
            }
        }
        .alert(
            LocalizedStringKey("settings.categories.deleteConfirmTitle"),
            isPresented: $showingDeleteAlert
        ) {
            Button(LocalizedStringKey("common.cancel"), role: .cancel) {}
            Button(LocalizedStringKey("common.delete"), role: .destructive) {
                performDeletion()
            }
        } message: {
            if let category = categoryToDelete {
                Text(LocalizedStringKey("settings.categories.deleteMessage \(category.name)"))
            }
        }
        .alert(
            LocalizedStringKey("error.title"),
            isPresented: $viewModel.showingError
        ) {
            Button(LocalizedStringKey("common.ok")) {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - View Components

    /// 加载状态视图
    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text(LocalizedStringKey("common.loading"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text(LocalizedStringKey("settings.categories.empty"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(LocalizedStringKey("settings.categories.emptyDescription"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    /// 分类列表视图
    private var categoriesListView: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.categories) { category in
                CategoryRowView(
                    category: category,
                    onEdit: { editingCategory = category },
                    onDelete: { showDeleteConfirmation(for: category) }
                )

                if category.id != viewModel.categories.last?.id {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    /// 添加分类按钮
    private var addCategoryButton: some View {
        Button(LocalizedStringKey("settings.categories.add")) {
            showingAddSheet = true
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Actions

    /// 显示删除确认对话框
    /// - Parameter category: 要删除的分类项目
    private func showDeleteConfirmation(for category: CategoryItem) {
        categoryToDelete = category
        showingDeleteAlert = true
    }

    /// 执行删除操作
    private func performDeletion() {
        if let category = categoryToDelete {
            viewModel.deleteCategory(category)
        }
        categoryToDelete = nil
    }
}

// MARK: - 分类行视图

/// 分类行视图组件
///
/// 显示单个分类的信息，包括名称、关键词和操作按钮。
/// 采用简洁的设计风格，提供直观的编辑和删除操作。
struct CategoryRowView: View {
    let category: CategoryItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)

                if !category.keywords.isEmpty {
                    Text(category.keywords.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(LocalizedStringKey("common.edit")) {
                    onEdit()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)

                Button(LocalizedStringKey("common.delete")) {
                    onDelete()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - 编辑表单

/// 分类编辑表单视图
///
/// 提供分类信息的新增和编辑功能，包括分类名称和关键词的输入。
/// 支持表单验证和数据保存操作。
struct CategoryEditSheet: View {
    let category: CategoryItem?
    let onSave: (CategoryItem) -> Void

    @State private var name: String = ""
    @State private var keywordsText: String = ""
    @Environment(\.dismiss) private var dismiss

    private var isEditing: Bool { category != nil }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
                    .lineLimit(3...)

                    Text(LocalizedStringKey("settings.categories.keywordsHint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        saveCategory()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .frame(width: 400, height: 350)
        .onAppear {
            if let category = category {
                name = category.name
                keywordsText = category.keywords.joined(separator: ", ")
            }
        }
    }

    /// 保存分类数据
    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let keywords =
            keywordsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let newCategory = CategoryItem(name: trimmedName, keywords: keywords)
        onSave(newCategory)
        dismiss()
    }
}

#Preview {
    CategoriesView()
        .frame(width: 500, height: 400)
}
