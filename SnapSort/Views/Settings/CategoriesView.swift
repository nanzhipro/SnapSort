//
//  CategoriesView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Foundation
import SwiftUI

// MARK: - Import Dependencies

// Import models and view models
// CategoryItem is defined in Models/CategoryModels.swift
// CategoriesViewModel is defined in ViewModels/CategoriesViewModel.swift

/// Categories Management View
///
/// Provides complete management functionality for screenshot categories, including category list display, adding, editing, and deleting operations.
/// Uses standard macOS settings page style with Form layout to display all categories.
/// Provides a clean and clear category management interface with intuitive editing and deletion operations.
/// Follows MVVM architecture, using CategoriesViewModel for data management.
struct CategoriesView: View {

    // MARK: - Properties

    /// Categories management view model
    @StateObject private var viewModel = CategoriesViewModel()

    /// Whether to display the add category form
    @State private var showingAddSheet = false

    /// Category being edited
    @State private var editingCategory: CategoryItem?

    /// Whether to display delete confirmation dialog
    @State private var showingDeleteAlert = false

    /// Category to be deleted
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

    /// Loading state view
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

    /// Empty state view
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

    /// Categories list view
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

    /// Add category button
    private var addCategoryButton: some View {
        Button(LocalizedStringKey("settings.categories.add")) {
            showingAddSheet = true
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Actions

    /// Show delete confirmation dialog
    /// - Parameter category: Category item to be deleted
    private func showDeleteConfirmation(for category: CategoryItem) {
        categoryToDelete = category
        showingDeleteAlert = true
    }

    /// Execute delete operation
    private func performDeletion() {
        if let category = categoryToDelete {
            viewModel.deleteCategory(category)
        }
        categoryToDelete = nil
    }
}

// MARK: - Category Row View

/// Category row view component
///
/// Displays information for a single category, including name, keywords, and action buttons.
/// Uses a clean design style, providing intuitive edit and delete operations.
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

// MARK: - Edit Form

/// Category edit form view
///
/// Provides functionality to add and edit category information, including input for category name and keywords.
/// Supports form validation and data saving operations.
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

    /// Save category data
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
