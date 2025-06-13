//
//  CategoriesViewModel.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Foundation
import SwiftUI
import os.log

/// Categories management view model
///
/// Handles business logic and data operations for category management, including
/// CRUD operations for categories, database interactions, and state management.
/// Follows MVVM architecture pattern and provides data binding for CategoriesView.
///
/// ## Key Features
/// - CRUD operations for category data
/// - Integration with DatabaseManager
/// - UI state management (loading, error handling)
/// - Real-time category data updates
@MainActor
final class CategoriesViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Category list data
    @Published var categories: [CategoryItem] = []

    /// Loading state
    @Published var isLoading = false

    /// Error message
    @Published var errorMessage: String?

    /// Whether to show error alert
    @Published var showingError = false

    // MARK: - Private Properties

    /// Database manager
    private let databaseManager: DatabaseManager

    /// Logger instance
    private let logger = Logger(
        subsystem: "com.snapsort.viewmodels", category: "CategoriesViewModel")

    // MARK: - Initialization

    /// Initialize categories view model
    /// - Parameter databaseManager: Database manager instance
    init(databaseManager: DatabaseManager = try! DatabaseManager()) {
        self.databaseManager = databaseManager
        loadCategories()
    }

    // MARK: - Public Methods

    /// Load all category data
    func loadCategories() {
        logger.debug("Loading categories from database")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let categoryMetadata = try databaseManager.getAllCategories()
                let categoryItems = categoryMetadata.map { metadata in
                    CategoryItem(name: metadata.name, keywords: metadata.keywords)
                }

                await MainActor.run {
                    self.categories = categoryItems
                    self.isLoading = false
                    self.logger.info("Successfully loaded \(categoryItems.count) categories")
                }
            } catch {
                await MainActor.run {
                    self.handleError(error, operation: "loading categories")
                }
            }
        }
    }

    /// Add new category
    /// - Parameter category: Category item to add
    func addCategory(_ category: CategoryItem) {
        logger.debug("Adding new category: \(category.name)")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try databaseManager.saveCategory(name: category.name, keywords: category.keywords)

                await MainActor.run {
                    self.categories.append(category)
                    self.isLoading = false
                    self.logger.info("Successfully added category: \(category.name)")
                }
            } catch {
                await MainActor.run {
                    self.handleError(error, operation: "adding category")
                }
            }
        }
    }

    /// Update existing category
    /// - Parameters:
    ///   - categoryId: Category ID
    ///   - updatedCategory: Updated category data
    func updateCategory(categoryId: CategoryItem.ID, updatedCategory: CategoryItem) {
        logger.debug("Updating category: \(updatedCategory.name)")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Delete old category first, then add new one (since name might change)
                if let oldCategory = categories.first(where: { $0.id == categoryId }) {
                    try databaseManager.deleteCategory(name: oldCategory.name)
                }
                try databaseManager.saveCategory(
                    name: updatedCategory.name, keywords: updatedCategory.keywords)

                await MainActor.run {
                    if let index = self.categories.firstIndex(where: { $0.id == categoryId }) {
                        self.categories[index] = updatedCategory
                    }
                    self.isLoading = false
                    self.logger.info("Successfully updated category: \(updatedCategory.name)")
                }
            } catch {
                await MainActor.run {
                    self.handleError(error, operation: "updating category")
                }
            }
        }
    }

    /// Delete single category
    /// - Parameter category: Category item to delete
    func deleteCategory(_ category: CategoryItem) {
        logger.debug("Deleting category: \(category.name)")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try databaseManager.deleteCategory(name: category.name)

                await MainActor.run {
                    self.categories.removeAll { $0.id == category.id }
                    self.isLoading = false
                    self.logger.info("Successfully deleted category: \(category.name)")
                }
            } catch {
                await MainActor.run {
                    self.handleError(error, operation: "deleting category")
                }
            }
        }
    }

    /// Batch delete categories
    /// - Parameter categoryIds: Set of category IDs to delete
    func deleteCategories(_ categoryIds: Set<CategoryItem.ID>) {
        logger.debug("Batch deleting \(categoryIds.count) categories")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let categoriesToDelete = categories.filter { categoryIds.contains($0.id) }

                for category in categoriesToDelete {
                    try databaseManager.deleteCategory(name: category.name)
                }

                await MainActor.run {
                    self.categories.removeAll { categoryIds.contains($0.id) }
                    self.isLoading = false
                    self.logger.info("Successfully deleted \(categoriesToDelete.count) categories")
                }
            } catch {
                await MainActor.run {
                    self.handleError(error, operation: "batch deleting categories")
                }
            }
        }
    }

    /// Check if category name already exists
    /// - Parameter name: Category name
    /// - Returns: Whether a category with the same name exists
    func isCategoryNameExists(_ name: String) -> Bool {
        return categories.contains { $0.name.lowercased() == name.lowercased() }
    }

    /// Search categories containing specified keyword
    /// - Parameter keyword: Search keyword
    /// - Returns: List of matching categories
    func searchCategories(byKeyword keyword: String) -> [CategoryItem] {
        guard !keyword.isEmpty else { return categories }

        return categories.filter { category in
            category.name.localizedCaseInsensitiveContains(keyword)
                || category.keywords.contains { $0.localizedCaseInsensitiveContains(keyword) }
        }
    }

    /// Get all category names separated by Chinese punctuation marks
    /// - Returns: String containing all category names separated by Chinese punctuation marks
    public func getAllCategoryNamesString() -> String {
        return categories.map { $0.name }.joined(separator: "、")
    }

    /// Clear error state
    func clearError() {
        errorMessage = nil
        showingError = false
    }

    // MARK: - Private Methods

    /// Handle error
    /// - Parameters:
    ///   - error: Error object
    ///   - operation: Operation description
    private func handleError(_ error: Error, operation: String) {
        isLoading = false

        let message: String
        if let dbError = error as? DatabaseManager.DatabaseError {
            switch dbError {
            case .categoryNotFound(let name):
                message = String(localized: "error.category.notFound \(name)")
            case .categoryAlreadyExists(let name):
                message = String(localized: "error.category.alreadyExists \(name)")
            case .operationFailed(let details):
                message = String(localized: "error.category.operationFailed \(details)")
            case .initializationFailed(let details):
                message = String(localized: "error.database.initializationFailed \(details)")
            default:
                message = String(localized: "error.category.unknown")
            }
        } else {
            message = String(localized: "error.category.unknown")
        }

        errorMessage = message
        showingError = true
        logger.error("Error \(operation): \(error.localizedDescription)")
    }
}
