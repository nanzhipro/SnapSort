//
//  ServiceManager.swift
//  SnapSort
//
//  Created by CursorAI on 2024-06-21.
//
//  The service manager is responsible for initializing and coordinating the operation of various service components.
//  This file implements the core workflow of the application, including screenshot processing, OCR text recognition,
//  AI classification, file organization, database updates, and notification sending, forming a complete processing chain.

import Foundation
import SwiftUI
import UserNotifications
import os.log

/// Service Manager
/// Manages the complete workflow for screenshot processing, including component lifecycle and configuration.
///
/// `ServiceManager` serves as the core coordinator of the application, responsible for:
/// - Initializing and configuring service components (screenshot monitor, OCR service, AI classifier, etc.)
/// - Coordinating interactions and data flow between components
/// - Managing error handling and recovery strategies
/// - Providing unified service start and stop interfaces
///
/// ## Workflow
///
/// 1. User screenshots are captured by the screenshot monitoring service (`ScreenshotMonitor`)
/// 2. Screenshots are passed to the OCR processor (`OCRProcessor`) for text recognition
/// 3. Recognition results are passed to the AI classifier (`AIClassifier`) for classification
/// 4. Classification results are used by the file organizer (`FileOrganizer`) to move screenshots to appropriate directories
/// 5. New file paths, recognized text, and classification results are saved to the database (`DatabaseManager`)
/// 6. Processing results are communicated to the user via the notification manager (`NotificationManager`)
///
/// ## Usage
///
/// ```swift
/// // Get service manager instance
/// let serviceManager = ServiceManager.shared
///
/// // Start all services
/// try await serviceManager.startServices()
///
/// // Stop services when application closes
/// await serviceManager.stopServices()
/// ```
public final class ServiceManager {
    // MARK: - Properties

    /// Screenshot monitoring service
    public private(set) var screenshotMonitor: ScreenshotMonitorProtocol

    /// OCR text recognition processor
    public private(set) var ocrProcessor: OCRProcessor

    /// AI classifier service
    public private(set) var aiClassifier: AIClassifier

    /// File organizer service
    public private(set) var fileOrganizer: FileOrganizerProtocol

    /// Database management service
    public private(set) var databaseManager: DatabaseManager

    /// Notification management service
    public private(set) var notificationManager: NotificationManagerProtocol

    /// System logger
    private let logger = Logger(subsystem: "com.snapsort.services", category: "ServiceManager")

    /// Singleton instance
    public static let shared = try! ServiceManager()

    // MARK: - Initialization

    /// Initialize service manager
    /// - Throws: Component errors that may occur during initialization
    public init() throws {
        logger.info("Initializing service components...")

        // Initialize screenshot monitor (ensure shared instance is used to avoid duplicates)
        self.screenshotMonitor = ScreenshotMonitor.shared
        logger.info("Screenshot monitor successfully initialized")

        // Initialize OCR processor
        self.ocrProcessor = OCRProcessor()
        logger.info("OCR processor successfully initialized")

        // Initialize AI classifier
        let apiHost =
            UserDefaults.standard.string(forKey: "ai_api_host") ?? "https://api.deepseek.com"
        guard let apiURL = URL(string: "\(apiHost)/v1") else {
            logger.error("Failed to initialize AI classifier: Invalid API URL format - \(apiHost)")
            throw ServiceError.invalidConfiguration(service: "AIClassifier", key: "apiURL")
        }

        // Read API key stored in binary from UserDefaults
        var apiKey: String = ""
        if let keyData = UserDefaults.standard.data(forKey: "ai_api_key_data"),
            let key = String(data: keyData, encoding: .utf8), !key.isEmpty
        {
            apiKey = key
            logger.info("API key loaded from secure storage")
        }

        let openAIClient = SimpleOpenAIClient(apiToken: apiKey, baseURL: apiURL)
        self.aiClassifier = AIClassifier(apiClient: openAIClient)
        logger.info("AI classifier successfully initialized with endpoint: \(apiHost)")

        // Use temporary directory as initial location for fileOrganizer, will update in setupServices later
        let tempDirectoryPath = (NSHomeDirectory() as NSString).appendingPathComponent(
            "Pictures/SnapSort")
        self.fileOrganizer = try FileOrganizer(baseDirectoryPath: tempDirectoryPath)

        // Initialize database manager
        self.databaseManager = try DatabaseManager()
        logger.info("Database manager successfully initialized")

        // Initialize notification manager
        self.notificationManager = NotificationManager()
        logger.info("Notification manager successfully initialized")

        logger.info("Service initialization completed")
    }

    /// 设置服务组件
    /// 在初始化后调用此方法完成需要异步处理的设置
    /// - Throws: 设置过程中可能发生的错误
    public func setupServices() async throws {
        // 获取系统截图位置并重新配置 fileOrganizer
        let baseDirectoryPath = try await getSystemScreenshotLocation()
        try fileOrganizer.updateBaseDirectory(path: baseDirectoryPath)
        logger.info("File organizer successfully updated with base directory: \(baseDirectoryPath)")

        logger.info("Service setup completed successfully")
    }

    // MARK: - 公共方法

    /// 启动所有服务
    /// - Throws: 服务启动过程中可能发生的错误
    public func startServices() async throws {
        logger.info("Starting service components...")

        // 设置服务组件（处理异步初始化）
        try await setupServices()

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

    /// 获取系统截图存储位置
    /// - Returns: 系统当前的截图存储路径
    private func getSystemScreenshotLocation() async throws -> String {
        do {
            let process = Process()
            let pipe = Pipe()

            process.standardOutput = pipe
            process.standardError = pipe
            process.arguments = ["-c", "defaults read com.apple.screencapture location"]
            process.executableURL = URL(fileURLWithPath: "/bin/sh")

            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                let location = output.trimmingCharacters(in: .whitespacesAndNewlines)
                if !location.isEmpty {
                    return location
                }
            }

            // Default return to "Pictures/SnapSort" directory
            return (NSHomeDirectory() as NSString).appendingPathComponent("Pictures/SnapSort")
        } catch {
            logger.error("Failed to get system screenshot location: \(error.localizedDescription)")
            return (NSHomeDirectory() as NSString).appendingPathComponent("Pictures/SnapSort")
        }
    }

    /// Configure screenshot handler callback
    private func setupScreenshotHandler() {
        screenshotMonitor.setScreenshotHandler { [weak self] screenshotURL in
            guard let self = self else { return }
            Task {
                await self.processScreenshot(url: screenshotURL)
            }
        }
    }

    /// Process new screenshot, executing the complete application workflow
    /// - Parameter url: URL of the captured screenshot file
    private func processScreenshot(url: URL) async {
        logger.info("Processing new screenshot captured at: \(url.path)")

        do {
            // 1. OCR text recognition
            logger.info("Starting OCR text recognition for: \(url.lastPathComponent)")
            let ocrResults = try await ocrProcessor.process(
                imagePath: url.path,
                languages: []
            )

            // Get formatted text results
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

            // Determine classification result
            let category: String
            if userCategories.isEmpty {
                // If user has not set up categories, skip AI classification and use default category name
                logger.info("No user categories defined, skipping AI classification")
                category = "Unclassified"
            } else {
                // User-defined categories exist, perform AI classification
                let classificationResult = try await aiClassifier.classify(
                    text: recognizedText,
                    categories: userCategories
                )
                category = classificationResult.category
                logger.info("Classification completed successfully with category: '\(category)'")
            }

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

    /// Get user-defined categories
    /// - Returns: Array of category objects containing category names and keywords
    private func getUserCategories() -> [CategoryItem] {
        do {
            // Try to get user-defined categories from the database
            let categories = try databaseManager.getAllCategories().map { metadata in
                CategoryItem(name: metadata.name, keywords: metadata.keywords)
            }

            if !categories.isEmpty {
                logger.debug("Retrieved \(categories.count) user-defined categories from database")
                return categories
            }

            // If no categories in database, try reading from UserDefaults
            if let categoriesData = UserDefaults.standard.data(forKey: "user_categories") {
                // First try parsing new format (categories with keywords)
                if let categoryItems = try? JSONDecoder().decode(
                    [CategoryItem].self, from: categoriesData)
                {
                    logger.debug(
                        "Retrieved \(categoryItems.count) category items from UserDefaults")
                    return categoryItems
                }

                // Backward compatibility: try parsing old format (category names only)
                if let categoryNames = try? JSONDecoder().decode(
                    [String].self, from: categoriesData)
                {
                    logger.debug(
                        "Retrieved \(categoryNames.count) category names from UserDefaults (legacy format)"
                    )
                    // Convert old format to new format
                    return categoryNames.map { CategoryItem(name: $0, keywords: []) }
                }
            }
        } catch {
            logger.error("Error retrieving categories: \(error.localizedDescription)")
        }

        // No user-defined categories, return empty array
        logger.debug("No user-defined categories found, returning empty array")
        return []
    }
}

/// Service operation error types
public enum ServiceError: Error, LocalizedError {
    /// Missing required configuration
    case configurationMissing(service: String, key: String)
    /// Invalid configuration value
    case invalidConfiguration(service: String, key: String)
    /// Service startup failed
    case startupFailed(service: String, reason: String)
    /// Processing stage failed
    case processingFailed(stage: String, reason: String)

    public var errorDescription: String? {
        switch self {
        case .configurationMissing(let service, let key):
            return "Configuration missing: \(service) requires \(key) configuration"
        case .invalidConfiguration(let service, let key):
            return "Invalid configuration: \(service)'s \(key) setting is invalid"
        case .startupFailed(let service, let reason):
            return "Service startup failed: \(service) - \(reason)"
        case .processingFailed(let stage, let reason):
            return "Processing failed: in \(stage) stage - \(reason)"
        }
    }
}
