//
//  CategoriesView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// 分类管理视图
///
/// 提供截图分类的完整管理功能，包括分类列表展示、新增、编辑和删除操作。
/// 采用列表布局展示所有分类，支持快速编辑和状态管理。
/// 集成分类编辑表单，提供流畅的用户交互体验。
struct CategoriesView: View {

    /// 设置视图模型引用
    @ObservedObject var viewModel: SettingsViewModel

    // MARK: - State

    /// 是否显示编辑表单
    @State private var showingEditSheet = false
    /// 当前编辑的分类（nil表示新增模式）
    @State private var editingCategory: Category?

    var body: some View {
        Form {
            categoryListSection
        }
        .padding()
        .sheet(isPresented: $showingEditSheet) {
            CategoryEditView(
                viewModel: viewModel,
                category: editingCategory
            )
        }
    }
}

// MARK: - View Components

extension CategoriesView {

    /// 分类列表区域
    @ViewBuilder
    fileprivate var categoryListSection: some View {
        Section {
            VStack(spacing: 12) {
                categoryList
                addButton
            }
        } header: {
            Text(LocalizedStringKey("settings.categories.management"))
        }
    }

    /// 分类列表
    @ViewBuilder
    fileprivate var categoryList: some View {
        List {
            ForEach(viewModel.categories) { category in
                CategoryRowView(category: category) {
                    editingCategory = category
                    showingEditSheet = true
                }
            }
            .onDelete(perform: deleteCategories)
        }
        .frame(minHeight: 200)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    /// 添加按钮
    @ViewBuilder
    fileprivate var addButton: some View {
        Button(LocalizedStringKey("settings.categories.add")) {
            editingCategory = nil
            showingEditSheet = true
        }
        .buttonStyle(.borderedProminent)
    }
}

// MARK: - Actions

extension CategoriesView {

    /// 删除分类
    /// - Parameter offsets: 要删除的分类索引集合
    fileprivate func deleteCategories(at offsets: IndexSet) {
        viewModel.deleteCategory(at: offsets)
    }
}

/// 分类行视图
///
/// 展示单个分类的详细信息，包括名称、关键词和状态。
/// 提供编辑入口和状态指示器，确保信息展示的清晰性。
struct CategoryRowView: View {

    /// 分类数据
    let category: Category
    /// 编辑回调
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            categoryInfo
            Spacer()
            statusIndicator
            editButton
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - CategoryRowView Components

extension CategoryRowView {

    /// 分类信息区域
    @ViewBuilder
    fileprivate var categoryInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.name)
                .font(.headline)
                .foregroundColor(.primary)

            if !category.keywords.isEmpty {
                Text(category.keywords.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Text(LocalizedStringKey("category.noKeywords"))
                    .font(.caption)
                    .foregroundColor(Color.secondary.opacity(0.7))
                    .italic()
            }
        }
    }

    /// 状态指示器
    @ViewBuilder
    fileprivate var statusIndicator: some View {
        if !category.isEnabled {
            Text(LocalizedStringKey("common.disabled"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
    }

    /// 编辑按钮
    @ViewBuilder
    fileprivate var editButton: some View {
        Button(LocalizedStringKey("common.edit")) {
            onEdit()
        }
        .buttonStyle(.borderless)
        .foregroundColor(.accentColor)
    }
}

#Preview {
    CategoriesView(viewModel: SettingsViewModel())
        .frame(width: 500, height: 400)
}
