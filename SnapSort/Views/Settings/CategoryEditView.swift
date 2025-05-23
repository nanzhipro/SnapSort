//
//  CategoryEditView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// 分类编辑视图
///
/// 提供分类的新增和编辑功能，支持分类名称、关键词列表的管理。
/// 采用Sheet模式展示，确保良好的用户交互体验。包含输入验证和实时预览功能，
/// 遵循Apple设计规范的表单布局和按钮交互。
struct CategoryEditView: View {

    // MARK: - Environment

    /// 用于关闭当前视图
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    /// 设置视图模型引用
    @ObservedObject var viewModel: SettingsViewModel

    /// 要编辑的分类（nil表示新增模式）
    let category: Category?

    // MARK: - State

    /// 分类名称输入
    @State private var categoryName: String = ""
    /// 关键词文本输入（多行）
    @State private var keywordsText: String = ""
    /// 是否启用此分类
    @State private var isEnabled: Bool = true

    // MARK: - Computed Properties

    /// 当前是否为编辑模式
    private var isEditingMode: Bool {
        category != nil
    }

    /// 保存按钮是否可用
    private var canSave: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                formContent
                Spacer()
            }
            .padding()
            .frame(minWidth: 400, minHeight: 350)
            .navigationTitle(
                isEditingMode
                    ? LocalizedStringKey("category.edit.title")
                    : LocalizedStringKey("category.add.title")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
        }
        .onAppear(perform: loadCategoryData)
    }
}

// MARK: - View Components

extension CategoryEditView {

    /// 表单内容
    @ViewBuilder
    fileprivate var formContent: some View {
        Form {
            nameSection
            keywordsSection
            optionsSection
        }
        .formStyle(.grouped)
    }

    /// 名称输入区域
    @ViewBuilder
    fileprivate var nameSection: some View {
        Section {
            TextField(
                LocalizedStringKey("category.edit.name"),
                text: $categoryName
            )
            .textFieldStyle(.roundedBorder)
        } header: {
            Text(LocalizedStringKey("category.edit.nameSection"))
        }
    }

    /// 关键词编辑区域
    @ViewBuilder
    fileprivate var keywordsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("category.edit.keywordsHelp"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $keywordsText)
                    .frame(minHeight: 100, maxHeight: 150)
                    .border(Color.secondary.opacity(0.3), width: 1)
                    .cornerRadius(4)
            }
        } header: {
            Text(LocalizedStringKey("category.edit.keywords"))
        }
    }

    /// 选项设置区域
    @ViewBuilder
    fileprivate var optionsSection: some View {
        Section {
            Toggle(
                LocalizedStringKey("category.edit.enabled"),
                isOn: $isEnabled
            )
        } header: {
            Text(LocalizedStringKey("category.edit.options"))
        }
    }

    /// 取消按钮
    @ViewBuilder
    fileprivate var cancelButton: some View {
        Button(LocalizedStringKey("common.cancel")) {
            dismiss()
        }
        .keyboardShortcut(.escape)
    }

    /// 保存按钮
    @ViewBuilder
    fileprivate var saveButton: some View {
        Button(LocalizedStringKey("common.save")) {
            saveCategory()
        }
        .keyboardShortcut(.return)
        .disabled(!canSave)
    }
}

// MARK: - Methods

extension CategoryEditView {

    /// 加载分类数据到表单
    fileprivate func loadCategoryData() {
        guard let category = category else { return }

        categoryName = category.name
        keywordsText = category.keywords.joined(separator: "\n")
        isEnabled = category.isEnabled
    }

    /// 保存分类数据
    fileprivate func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let processedKeywords = extractKeywords(from: keywordsText)

        if let existingCategory = category {
            // 编辑模式：更新现有分类
            var updatedCategory = existingCategory
            updatedCategory.name = trimmedName
            updatedCategory.keywords = processedKeywords
            updatedCategory.isEnabled = isEnabled
            viewModel.updateCategory(updatedCategory)
        } else {
            // 新增模式：创建新分类
            let newCategory = Category(
                name: trimmedName,
                keywords: processedKeywords
            )
            viewModel.addCategory(newCategory)
        }

        dismiss()
    }

    /// 从文本中提取关键词列表
    /// - Parameter text: 包含关键词的多行文本
    /// - Returns: 处理后的关键词数组
    fileprivate func extractKeywords(from text: String) -> [String] {
        return
            text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

#Preview {
    CategoryEditView(
        viewModel: SettingsViewModel(),
        category: nil
    )
}
