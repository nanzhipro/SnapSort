//
//  ServiceManager.swift
//  SnapSort
//
//  Created by CursorAI on 2024-06-21.
//
//  服务管理器负责初始化和协调各个服务组件的运行。
//  该文件实现了应用程序的核心工作流，包括截图处理、OCR文本识别、
//  AI分类、文件组织、数据库更新和通知发送，形成一个完整的处理链。

import Foundation
import SwiftUI
import UserNotifications
import os.log

/// 服务管理器
/// 管理截图处理的完整工作流程，包括各组件的生命周期和配置。
///
/// `ServiceManager` 作为应用的核心协调器，负责以下任务：
/// - 初始化和配置各个服务组件（截图监控、OCR服务、AI分类器等）
/// - 协调组件间的交互和数据流转
/// - 管理错误处理和恢复策略
/// - 提供统一的服务启动和停止接口
///
/// ## 工作流程
///
/// 1. 用户截图被截图监控服务(`ScreenshotMonitor`)捕获
/// 2. 截图交给OCR处理器(`OCRProcessor`)进行文本识别
/// 3. 识别结果传递给AI分类器(`AIClassifier`)进行分类
/// 4. 分类结果用于文件组织器(`FileOrganizer`)将截图移动到相应目录
/// 5. 新的文件路径、识别文本和分类结果保存到数据库(`DatabaseManager`)
/// 6. 处理结果通过通知管理器(`NotificationManager`)通知用户
///
/// ## 使用方式
///
/// ```swift
/// // 获取服务管理器实例
/// let serviceManager = ServiceManager.shared
///
/// // 启动所有服务
/// try await serviceManager.startServices()
///
/// // 在应用关闭时停止服务
/// await serviceManager.stopServices()
/// ```
public final class ServiceManager {
    // MARK: - 属性

    /// 截图监控服务
    public private(set) var screenshotMonitor: ScreenshotMonitorProtocol

    /// OCR文本识别处理器
    public private(set) var ocrProcessor: OCRProcessor

    /// AI分类器服务
    public private(set) var aiClassifier: AIClassifier

    /// 文件组织器服务
    public private(set) var fileOrganizer: FileOrganizerProtocol

    /// 数据库管理服务
    public private(set) var databaseManager: DatabaseManager

    /// 通知管理服务
    public private(set) var notificationManager: NotificationManagerProtocol

    /// 系统日志记录器
    private let logger = Logger(subsystem: "com.snapsort.services", category: "ServiceManager")

    /// 单例实例
    public static let shared = try! ServiceManager()

    // MARK: - 初始化

    /// 初始化服务管理器
    /// - Throws: 初始化过程中可能发生的组件错误
    public init() throws {
        logger.info("Initializing service components...")

        // Initialize screenshot monitor (ensure shared instance is used to avoid duplicates)
        self.screenshotMonitor = ScreenshotMonitor.shared
        logger.info("Screenshot monitor successfully initialized")

        // Initialize OCR processor
        self.ocrProcessor = OCRProcessor()
        logger.info("OCR processor successfully initialized")

        // Initialize AI classifier
        // guard let apiKey = UserDefaults.standard.string(forKey: "ai_api_key") else {
        //     logger.error("Failed to initialize AI classifier: API key not configured")
        //     throw ServiceError.configurationMissing(service: "AIClassifier", key: "apiKey")
        // }

        let apiHost =
            UserDefaults.standard.string(forKey: "ai_api_host") ?? "https://api.deepseek.com"
        guard let apiURL = URL(string: "\(apiHost)/v1") else {
            logger.error("Failed to initialize AI classifier: Invalid API URL format - \(apiHost)")
            throw ServiceError.invalidConfiguration(service: "AIClassifier", key: "apiURL")
        }

        let openAIClient = SimpleOpenAIClient(
            apiToken: "sk-3c0a5904963144d0b8a735b40b04e725", baseURL: apiURL)
        self.aiClassifier = AIClassifier(apiClient: openAIClient)
        logger.info("AI classifier successfully initialized with endpoint: \(apiHost)")

        // Initialize file organizer
        let baseDirectoryPath =
            UserDefaults.standard.string(forKey: "file_base_directory")
            ?? (NSHomeDirectory() as NSString).appendingPathComponent("Pictures/SnapSort")
        self.fileOrganizer = try FileOrganizer(baseDirectoryPath: baseDirectoryPath)
        logger.info(
            "File organizer successfully initialized with base directory: \(baseDirectoryPath)")

        // Initialize database manager
        self.databaseManager = try DatabaseManager()
        logger.info("Database manager successfully initialized")

        // Initialize notification manager
        self.notificationManager = NotificationManager()
        logger.info("Notification manager successfully initialized")

        logger.info("Service initialization completed successfully")
    }

    // MARK: - 公共方法

    /// 启动所有服务
    /// - Throws: 服务启动过程中可能发生的错误
    public func startServices() async throws {
        logger.info("Starting service components...")

        // Request notification authorization
        let notificationAuthorized = await notificationManager.requestAuthorization()
        logger.info(
            "Notification authorization status: \(notificationAuthorized ? "granted" : "denied")")

        // Start screenshot monitoring on main actor (NSMetadataQuery requires main run loop)
        do {
            try await MainActor.run {
                try screenshotMonitor.startMonitoring()
            }
            logger.info("Screenshot monitoring started successfully")
        } catch {
            logger.error("Failed to start screenshot monitoring: \(error.localizedDescription)")
            throw ServiceError.startupFailed(
                service: "ScreenshotMonitor", reason: error.localizedDescription)
        }

        // Set up screenshot handler
        setupScreenshotHandler()
        logger.info("Screenshot handler configured successfully")

        logger.info("All services started successfully")
    }

    /// 停止所有服务
    public func stopServices() async {
        logger.info("Stopping service components...")

        // Stop screenshot monitoring (ensure main actor)
        await MainActor.run {
            screenshotMonitor.stopMonitoring()
        }
        logger.info("Screenshot monitoring stopped")

        // Clean up OCR processor resources
        await MainActor.run {
            ocrProcessor.cleanup()
        }
        logger.info("OCR processor resources cleaned up")

        logger.info("All services stopped successfully")
    }

    // MARK: - 私有方法

    /// 配置截图处理回调
    private func setupScreenshotHandler() {
        screenshotMonitor.setScreenshotHandler { [weak self] screenshotURL in
            guard let self = self else { return }
            Task {
                await self.processScreenshot(url: screenshotURL)
            }
        }
    }

    /// 处理新截图，执行完整的应用工作流
    /// - Parameter url: 捕获到的截图文件URL
    private func processScreenshot(url: URL) async {
        logger.info("Processing new screenshot captured at: \(url.path)")

        do {
            // 1. OCR text recognition
            logger.info("Starting OCR text recognition for: \(url.lastPathComponent)")
            let ocrResults = try await ocrProcessor.process(
                imagePath: url.path,
                languages: []
            )

            // 获取格式化文本结果
            let recognizedText = ocrProcessor.getFormattedText(from: ocrResults)
            if recognizedText.isEmpty {
                let errorMessage = "No text content detected in screenshot"
                logger.error("\(errorMessage): \(url.lastPathComponent)")
                throw ServiceError.processingFailed(
                    stage: "OCR",
                    reason: errorMessage
                )
            }

            logger.info(
                "OCR completed successfully with \(recognizedText.count) characters of text")

            // 2. AI classification
            logger.info("Starting AI classification for screenshot content")
            let userCategories = getUserCategories()
            let classificationResult = try await aiClassifier.classify(
                text: recognizedText,
                categories: userCategories
            )

            let category = classificationResult.category
            logger.info("Classification completed successfully with category: '\(category)'")

            // 3. File organization
            logger.info("Moving screenshot to classification directory: '\(category)'")
            let newFilePath = try fileOrganizer.moveScreenshot(
                from: url,
                to: category
            )

            logger.info("File successfully moved to: \(newFilePath.path)")

            // 4. Database update
            logger.info("Updating database with screenshot metadata")
            try databaseManager.saveScreenshot(
                path: newFilePath.path,
                text: recognizedText,
                classification: category
            )

            logger.info("Database updated successfully with new screenshot record")

            // 5. Send notification
            logger.info("Sending classification success notification")
            notificationManager.sendClassificationNotification(
                category: category,
                filename: url.lastPathComponent
            )

            logger.info("Screenshot processing workflow completed successfully")
        } catch let error as AIClassifierError {
            logger.error("AI classification failed: \(error.localizedDescription)")
            notificationManager.sendErrorNotification(error: error)
        } catch let error as FileOrganizerError {
            logger.error("File organization failed: \(error.localizedDescription)")
            notificationManager.sendErrorNotification(error: error)
        } catch let error as OCRError {
            logger.error("OCR processing failed: \(error.localizedDescription)")
            notificationManager.sendErrorNotification(error: error)
        } catch let error as DatabaseManager.DatabaseError {
            logger.error("Database operation failed: \(error.localizedDescription)")
            notificationManager.sendErrorNotification(error: error)
        } catch {
            logger.error(
                "Unexpected error during screenshot processing: \(error.localizedDescription)")
            notificationManager.sendErrorNotification(error: error)
        }
    }

    /// 获取用户自定义分类类别
    /// - Returns: 分类类别名称数组
    private func getUserCategories() -> [String] {
        if let categoriesData = UserDefaults.standard.data(forKey: "user_categories"),
            let categories = try? JSONDecoder().decode([String].self, from: categoriesData)
        {
            logger.debug("Retrieved \(categories.count) user-defined categories")
            return categories
        }

        // Default categories
        let defaultCategories = ["Work", "Study", "Personal", "Entertainment"]
        logger.debug("Using default categories: \(defaultCategories.joined(separator: ", "))")
        return defaultCategories
    }
}

/// 服务操作错误类型
public enum ServiceError: Error, LocalizedError {
    /// 缺少必要配置
    case configurationMissing(service: String, key: String)
    /// 配置值无效
    case invalidConfiguration(service: String, key: String)
    /// 服务启动失败
    case startupFailed(service: String, reason: String)
    /// 处理阶段失败
    case processingFailed(stage: String, reason: String)

    public var errorDescription: String? {
        switch self {
        case .configurationMissing(let service, let key):
            return "配置缺失：\(service) 需要 \(key) 配置"
        case .invalidConfiguration(let service, let key):
            return "配置无效：\(service) 的 \(key) 设置无效"
        case .startupFailed(let service, let reason):
            return "服务启动失败：\(service) - \(reason)"
        case .processingFailed(let stage, let reason):
            return "处理失败：在 \(stage) 阶段 - \(reason)"
        }
    }
}
