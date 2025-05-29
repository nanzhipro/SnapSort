//
//  CategoriesViewModel.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Foundation
import SwiftUI
import os.log

/// 分类管理视图模型
///
/// 负责处理分类管理的业务逻辑和数据操作，包括分类的增删改查、
/// 数据库交互和状态管理。遵循 MVVM 架构模式，为 CategoriesView 提供数据绑定。
///
/// ## 主要功能
/// - 分类数据的 CRUD 操作
/// - 与 DatabaseManager 的集成
/// - UI 状态管理（加载、错误处理）
/// - 分类数据的实时更新
@MainActor
final class CategoriesViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 分类列表数据
    @Published var categories: [CategoryItem] = []

    /// 加载状态
    @Published var isLoading = false

    /// 错误信息
    @Published var errorMessage: String?

    /// 是否显示错误警告
    @Published var showingError = false

    // MARK: - Private Properties

    /// 数据库管理器
    private let databaseManager: DatabaseManager

    /// 日志记录器
    private let logger = Logger(
        subsystem: "com.snapsort.viewmodels", category: "CategoriesViewModel")

    // MARK: - Initialization

    /// 初始化分类视图模型
    /// - Parameter databaseManager: 数据库管理器实例
    init(databaseManager: DatabaseManager = try! DatabaseManager()) {
        self.databaseManager = databaseManager
        loadCategories()
    }

    // MARK: - Public Methods

    /// 加载所有分类数据
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

    /// 添加新分类
    /// - Parameter category: 要添加的分类项目
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

    /// 更新现有分类
    /// - Parameters:
    ///   - categoryId: 分类 ID
    ///   - updatedCategory: 更新后的分类数据
    func updateCategory(categoryId: CategoryItem.ID, updatedCategory: CategoryItem) {
        logger.debug("Updating category: \(updatedCategory.name)")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // 先删除旧分类，再添加新分类（因为名称可能改变）
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

    /// 删除单个分类
    /// - Parameter category: 要删除的分类项目
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

    /// 批量删除分类
    /// - Parameter categoryIds: 要删除的分类 ID 集合
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

    /// 检查分类名称是否已存在
    /// - Parameter name: 分类名称
    /// - Returns: 是否存在同名分类
    func isCategoryNameExists(_ name: String) -> Bool {
        return categories.contains { $0.name.lowercased() == name.lowercased() }
    }

    /// 搜索包含指定关键词的分类
    /// - Parameter keyword: 搜索关键词
    /// - Returns: 匹配的分类列表
    func searchCategories(byKeyword keyword: String) -> [CategoryItem] {
        guard !keyword.isEmpty else { return categories }

        return categories.filter { category in
            category.name.localizedCaseInsensitiveContains(keyword)
                || category.keywords.contains { $0.localizedCaseInsensitiveContains(keyword) }
        }
    }

    /// 清除错误状态
    func clearError() {
        errorMessage = nil
        showingError = false
    }

    // MARK: - Private Methods

    /// 处理错误
    /// - Parameters:
    ///   - error: 错误对象
    ///   - operation: 操作描述
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
