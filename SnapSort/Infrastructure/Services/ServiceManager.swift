//
//  ServiceManager.swift
//  SnapSort
//
//  Created by CursorAI on 2024-06-21.
//

import Foundation
// 导入所有服务组件
@_implementationOnly import SnapSort
import os.log

/// 服务管理器
/// 负责初始化和管理应用的各个服务组件
public final class ServiceManager {
    // MARK: - 属性

    /// 截图监控服务
    public private(set) var screenshotMonitor: ScreenshotMonitorProtocol

    /// OCR服务
    public private(set) var ocrService: OCRServiceProtocol

    /// AI分类器服务
    public private(set) var aiClassifier: AIClassifier

    /// 文件组织器服务
    public private(set) var fileOrganizer: FileOrganizerProtocol

    /// 数据库管理服务
    public private(set) var databaseManager: DatabaseManager

    /// 通知管理服务
    public private(set) var notificationManager: NotificationManagerProtocol

    /// 日志记录器
    private let logger = Logger(subsystem: "com.snapsort.services", category: "ServiceManager")

    /// 单例实例
    public static let shared = try! ServiceManager()

    // MARK: - 初始化方法

    /// 初始化服务管理器
    /// - Throws: 初始化过程中可能发生的错误
    public init() throws {
        logger.info("Starting service initialization...")

        // Initialize screenshot monitor
        self.screenshotMonitor = DefaultScreenshotMonitor()
        logger.info("Screenshot monitor initialized")

        // Initialize OCR service
        self.ocrService = OCRService(configuration: .default)
        logger.info("OCR service initialized")

        // Initialize AI classifier
        guard let apiKey = UserDefaults.standard.string(forKey: "ai_api_key") else {
            logger.error("AI API key not configured")
            throw ServiceError.configurationMissing(service: "AIClassifier", key: "apiKey")
        }

        let apiHost =
            UserDefaults.standard.string(forKey: "ai_api_host") ?? "https://api.deepseek.com"
        guard let apiURL = URL(string: "\(apiHost)/v1") else {
            logger.error("Invalid AI API URL: \(apiHost)")
            throw ServiceError.invalidConfiguration(service: "AIClassifier", key: "apiURL")
        }

        let openAIClient = SimpleOpenAIClient(apiToken: apiKey, baseURL: apiURL)
        self.aiClassifier = AIClassifier(apiClient: openAIClient)
        logger.info("AI classifier initialized")

        // Initialize file organizer
        let baseDirectoryPath =
            UserDefaults.standard.string(forKey: "file_base_directory")
            ?? (NSHomeDirectory() as NSString).appendingPathComponent("Pictures/SnapSort")
        self.fileOrganizer = try FileOrganizer(baseDirectoryPath: baseDirectoryPath)
        logger.info("File organizer initialized with base directory: \(baseDirectoryPath)")

        // Initialize database manager
        self.databaseManager = try DatabaseManager()
        logger.info("Database manager initialized")

        // Initialize notification manager
        self.notificationManager = NotificationManager()
        logger.info("Notification manager initialized")

        logger.info("All service components initialized successfully")
    }

    // MARK: - 公共方法

    /// 启动所有服务
    /// - Throws: 启动过程中可能发生的错误
    public func startServices() async throws {
        logger.info("Starting services...")

        // Request notification authorization
        let notificationAuthorized = await notificationManager.requestAuthorization()
        logger.info(
            "Notification authorization status: \(notificationAuthorized ? "granted" : "denied")")

        // Start screenshot monitoring
        try screenshotMonitor.startMonitoring()

        // Set up screenshot handler
        setupScreenshotHandler()

        logger.info("All services started successfully")
    }

    /// 停止所有服务
    public func stopServices() async {
        logger.info("Stopping services...")

        // Stop screenshot monitoring
        screenshotMonitor.stopMonitoring()

        // Clean up OCR service resources
        await ocrService.cleanup()

        logger.info("All services stopped successfully")
    }

    // MARK: - 私有方法

    /// 设置截图处理回调
    private func setupScreenshotHandler() {
        screenshotMonitor.setScreenshotHandler { [weak self] screenshotURL in
            guard let self = self else { return }
            Task {
                await self.processScreenshot(url: screenshotURL)
            }
        }
    }

    /// 处理新截图
    /// - Parameter url: 截图文件URL
    private func processScreenshot(url: URL) async {
        logger.info("Processing new screenshot: \(url.path)")

        do {
            // 1. OCR text recognition
            let ocrResults = try await ocrService.recognizeText(
                from: url.path,
                preferredLanguages: []
            )

            guard let firstResult = ocrResults.first else {
                throw ServiceError.processingFailed(
                    stage: "OCR",
                    reason: "No OCR results obtained"
                )
            }

            let recognizedText = firstResult.text
            logger.info("OCR completed with text length: \(recognizedText.count)")

            // 2. AI classification
            let userCategories = getUserCategories()
            let classificationResult = try await aiClassifier.classify(
                text: recognizedText,
                categories: userCategories
            )

            let category = classificationResult.category
            logger.info("AI classification completed with result: \(category)")

            // 3. File organization
            let newFilePath = try fileOrganizer.moveScreenshot(
                from: url,
                to: category
            )

            logger.info("File moved successfully to: \(newFilePath.path)")

            // 4. Database update
            try databaseManager.saveScreenshot(
                path: newFilePath.path,
                text: recognizedText,
                classification: category
            )

            logger.info("Database updated successfully")

            // 5. Send notification
            notificationManager.sendClassificationNotification(
                category: category,
                filename: url.lastPathComponent
            )

            logger.info("Screenshot processing completed successfully")
        } catch {
            logger.error("Screenshot processing failed: \(error.localizedDescription)")
            notificationManager.sendErrorNotification(error: error)
        }
    }

    /// 获取用户配置的分类类别
    /// - Returns: 分类类别数组
    private func getUserCategories() -> [String] {
        if let categoriesData = UserDefaults.standard.data(forKey: "user_categories"),
            let categories = try? JSONDecoder().decode([String].self, from: categoriesData)
        {
            return categories
        }

        // 默认分类
        return ["工作", "学习", "生活", "娱乐"]
    }
}

/// 服务错误类型
public enum ServiceError: Error {
    /// 配置缺失
    case configurationMissing(service: String, key: String)
    /// 配置无效
    case invalidConfiguration(service: String, key: String)
    /// 处理失败
    case processingFailed(stage: String, reason: String)

    public var localizedDescription: String {
        switch self {
        case .configurationMissing(let service, let key):
            return "Missing configuration: \(service) requires \(key)"
        case .invalidConfiguration(let service, let key):
            return "Invalid configuration: \(service) has invalid \(key) setting"
        case .processingFailed(let stage, let reason):
            return "Processing failed: error in \(stage) stage - \(reason)"
        }
    }
}
