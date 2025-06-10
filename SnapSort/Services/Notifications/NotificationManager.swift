//
//  NotificationManager.swift
//  SnapSort
//
//  Created by CursorAI on 2024-06-21.
//

import Foundation
import UserNotifications
import os.log

/// Notification manager protocol
/// Defines the interface for notification management components
public protocol NotificationManagerProtocol {
    /// Request notification authorization from the user
    func requestAuthorization() async -> Bool

    /// Send notification about screenshot classification completion
    /// - Parameters:
    ///   - category: The category assigned to the screenshot
    ///   - filename: The filename of the screenshot
    func sendClassificationNotification(category: String, filename: String)

    /// Send notification about processing errors
    /// - Parameter error: The error that occurred
    func sendErrorNotification(error: Error)
}

/// Notification Manager
/// Manages system notifications to inform users about screenshot classification and errors
public final class NotificationManager: NotificationManagerProtocol {

    /// Notification center instance
    private let notificationCenter = UNUserNotificationCenter.current()

    /// Logger for notification events
    private let logger = Logger(
        subsystem: "com.snapsort.notifications", category: "NotificationManager")

    /// Notification category identifiers
    private enum NotificationCategory {
        static let classification = "CLASSIFICATION_NOTIFICATION"
        static let error = "ERROR_NOTIFICATION"
    }

    /// Initialize the notification manager
    public init() {
        setupNotificationCategories()
        logger.info("Notification manager initialized")
    }

    /// Configure notification categories
    private func setupNotificationCategories() {
        // Classification notification category
        let classificationCategory = UNNotificationCategory(
            identifier: NotificationCategory.classification,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Error notification category
        let errorCategory = UNNotificationCategory(
            identifier: NotificationCategory.error,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Register notification categories
        notificationCenter.setNotificationCategories([classificationCategory, errorCategory])
    }

    /// Request notification authorization from the user
    /// - Returns: Whether authorization was granted
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [
                .alert, .sound,
            ])
            logger.info("Notification authorization status: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error(
                "Failed to request notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    /// Send notification about screenshot classification completion
    /// - Parameters:
    ///   - category: The category assigned to the screenshot
    ///   - filename: The filename of the screenshot
    public func sendClassificationNotification(category: String, filename: String) {
        // 添加通知状态检查
        guard UserDefaults.standard.bool(forKey: "showNotifications") else {
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Screenshot Classified"
        content.body = "Screenshot \"\(filename)\" has been classified as \"\(category)\""
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.classification

        sendNotification(identifier: UUID().uuidString, content: content)
    }

    /// Send notification about processing errors
    /// - Parameter error: The error that occurred
    public func sendErrorNotification(error: Error) {
        // 添加通知状态检查
        guard UserDefaults.standard.bool(forKey: "showNotifications") else {
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Processing Error"
        content.body = "Error processing screenshot: \(error.localizedDescription)"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.error

        sendNotification(identifier: UUID().uuidString, content: content)
    }

    /// Internal notification delivery method
    /// - Parameters:
    ///   - identifier: Unique identifier for the notification
    ///   - content: Notification content
    private func sendNotification(identifier: String, content: UNNotificationContent) {
        // Create notification request (immediate delivery)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        // Add notification request
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to deliver notification: \(error.localizedDescription)")
            }
        }
    }
}
