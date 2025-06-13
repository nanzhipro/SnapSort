//
//  GeneralSettingsViewModel.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import Combine
import Foundation
import os.log

/// General settings view model
///
/// Manages basic application settings including notification permissions and
/// system screenshot directory configuration. Follows MVVM architecture pattern
/// and provides reactive settings state management and business logic processing.
/// Uses Combine framework for reactive state change updates.
@MainActor
final class GeneralSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Whether to show notifications
    @Published var showNotifications: Bool = true {
        didSet {
            handleNotificationSettingChange()
        }
    }

    /// Current screenshot storage directory
    @Published var screenshotDirectory: String = ""

    /// Directory selection state
    @Published var isDirectorySelected: Bool = false

    /// Notification permission status
    @Published var notificationAuthorizationStatus: String = "Unknown"

    // MARK: - Dependencies

    private let notificationManager: NotificationManagerProtocol
    private let logger = Logger(
        subsystem: "com.snapsort.settings", category: "GeneralSettingsViewModel")

    // MARK: - Initialization

    /// Initialize view model
    /// - Parameter notificationManager: Notification manager instance
    init(notificationManager: NotificationManagerProtocol = NotificationManager()) {
        self.notificationManager = notificationManager
        loadInitialSettings()
    }

    // MARK: - Public Methods

    /// Select screenshot storage directory
    /// - Parameter directoryURL: User selected directory URL
    func selectScreenshotDirectory(_ directoryURL: URL) {
        // This functionality is now handled by ScreenshotMonitor directly
        // through the UI, so this method is simplified
        logger.info("Screenshot directory selection handled by ScreenshotMonitor")
    }

    /// Refresh current settings state
    func refreshSettings() {
        Task {
            await loadCurrentScreenshotLocation()
            await checkNotificationAuthorization()
        }
    }

    // MARK: - Private Methods

    /// Load initial settings
    private func loadInitialSettings() {
        // Load notification settings from UserDefaults
        showNotifications = UserDefaults.standard.bool(forKey: "showNotifications")

        Task {
            await loadCurrentScreenshotLocation()
            await checkNotificationAuthorization()
        }
    }

    /// Handle notification setting changes
    private func handleNotificationSettingChange() {
        UserDefaults.standard.set(showNotifications, forKey: "showNotifications")

        if showNotifications {
            Task {
                let granted = await notificationManager.requestAuthorization()
                await MainActor.run {
                    notificationAuthorizationStatus = granted ? "Authorized" : "Denied"
                }
            }
        } else {
            notificationAuthorizationStatus = "Disabled"
        }

        logger.info("Notification setting changed to: \(self.showNotifications)")
    }

    /// Check notification authorization status
    private func checkNotificationAuthorization() async {
        // Logic for checking current notification permission status can be added here
        // Since NotificationManager currently doesn't provide status query method, using setting value temporarily
        await MainActor.run {
            notificationAuthorizationStatus = self.showNotifications ? "Enabled" : "Disabled"
        }
    }

    /// Load current system screenshot storage location
    private func loadCurrentScreenshotLocation() async {
        // Use ScreenshotMonitor to get current location (sandbox-compatible)
        await MainActor.run {
            screenshotDirectory = ScreenshotMonitor.shared.getScreenshotLocation()
            isDirectorySelected = ScreenshotMonitor.shared.hasUserSelectedFolder()
        }
    }
}

// MARK: - Error Types

/// Settings related error types
enum SettingsError: LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let output):
            return "Command execution failed: \(output)"
        }
    }
}
