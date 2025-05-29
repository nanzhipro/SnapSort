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
/// 提供简洁清晰的分类管理界面，支持滑动删除、批量删除和删除确认操作。
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

    /// 待删除的单个分类
    @State private var categoryToDelete: CategoryItem?

    /// 是否处于编辑模式
    @State private var isEditMode = false

    /// 选中的分类 ID 集合
    @State private var selectedCategories: Set<CategoryItem.ID> = []

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                headerView

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.categories.isEmpty {
                    emptyStateView
                } else {
                    categoriesListView
                }

                actionButtonsView
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
            deleteAlertMessage
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

    /// 头部视图
    private var headerView: some View {
        HStack {
            Text(LocalizedStringKey("settings.categories.management"))
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            if !viewModel.categories.isEmpty && !viewModel.isLoading {
                Button(
                    isEditMode
                        ? LocalizedStringKey("common.done")
                        : LocalizedStringKey("common.edit")
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditMode.toggle()
                        if !isEditMode {
                            selectedCategories.removeAll()
                        }
                    }
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.bottom, 8)
    }

    /// 加载状态视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text(LocalizedStringKey("common.loading"))
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(LocalizedStringKey("settings.categories.empty"))
                .font(.headline)
                .foregroundColor(.secondary)

            Text(LocalizedStringKey("settings.categories.emptyDescription"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    /// 分类列表视图
    private var categoriesListView: some View {
        List {
            ForEach(viewModel.categories) { category in
                CategoryRowView(
                    category: category,
                    isEditMode: isEditMode,
                    isSelected: selectedCategories.contains(category.id),
                    onEdit: { editingCategory = category },
                    onDelete: { showDeleteConfirmation(for: category) },
                    onToggleSelection: {
                        if selectedCategories.contains(category.id) {
                            selectedCategories.remove(category.id)
                        } else {
                            selectedCategories.insert(category.id)
                        }
                    }
                )
            }
            .onDelete(perform: isEditMode ? nil : deleteCategories)
        }
        .frame(minHeight: 200)
    }

    /// 操作按钮视图
    private var actionButtonsView: some View {
        HStack {
            Button(LocalizedStringKey("settings.categories.add")) {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            if isEditMode && !selectedCategories.isEmpty {
                Spacer()

                Button(LocalizedStringKey("common.delete")) {
                    showBatchDeleteConfirmation()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .disabled(viewModel.isLoading)
            }
        }
        .padding(.top, 8)
    }

    /// 删除确认对话框消息
    private var deleteAlertMessage: some View {
        Group {
            if selectedCategories.count > 1 {
                Text(
                    LocalizedStringKey(
                        "settings.categories.batchDeleteMessage \(selectedCategories.count)"))
            } else if let category = categoryToDelete {
                Text(LocalizedStringKey("settings.categories.deleteMessage \(category.name)"))
            }
        }
    }

    // MARK: - Actions

    /// 显示单个分类的删除确认对话框
    /// - Parameter category: 要删除的分类项目
    private func showDeleteConfirmation(for category: CategoryItem) {
        categoryToDelete = category
        selectedCategories.removeAll()
        showingDeleteAlert = true
    }

    /// 显示批量删除确认对话框
    private func showBatchDeleteConfirmation() {
        categoryToDelete = nil
        showingDeleteAlert = true
    }

    /// 执行删除操作
    private func performDeletion() {
        if let category = categoryToDelete {
            // 单个删除
            viewModel.deleteCategory(category)
        } else if !selectedCategories.isEmpty {
            // 批量删除
            viewModel.deleteCategories(selectedCategories)
            selectedCategories.removeAll()
        }

        categoryToDelete = nil

        // 退出编辑模式
        if isEditMode && selectedCategories.isEmpty {
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditMode = false
            }
        }
    }

    /// 删除指定位置的分类项目（滑动删除）
    /// - Parameter offsets: 要删除的项目索引集合
    private func deleteCategories(at offsets: IndexSet) {
        let categoriesToDelete = offsets.map { viewModel.categories[$0] }

        for category in categoriesToDelete {
            viewModel.deleteCategory(category)
        }
    }
}

// MARK: - 分类行视图

/// 分类行视图组件
///
/// 显示单个分类的信息，包括名称、关键词和操作按钮。
/// 支持编辑模式下的选择状态和操作按钮显示。
struct CategoryRowView: View {
    let category: CategoryItem
    let isEditMode: Bool
    let isSelected: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleSelection: () -> Void

    var body: some View {
        HStack {
            if isEditMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.plain)
            }

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

            if !isEditMode {
                HStack(spacing: 8) {
                    Button(LocalizedStringKey("common.edit")) {
                        onEdit()
                    }
                    .buttonStyle(.borderless)

                    Button(LocalizedStringKey("common.delete")) {
                        onDelete()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditMode {
                onToggleSelection()
            }
        }
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
                        .textFieldStyle(.roundedBorder)
                }

                Section(LocalizedStringKey("settings.categories.keywords")) {
                    TextField(
                        LocalizedStringKey("settings.categories.keywordsPlaceholder"),
                        text: $keywordsText, axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)

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
