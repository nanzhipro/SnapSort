//
//  ScreenshotMonitor.swift
//  ScreenshotMonitor
//
//  Created by CursorAI on 2024-05-22.
//

import Foundation
import os

// MARK: - Screenshot Monitoring Protocol

/// Screenshot Monitor Protocol
/// Defines the basic functional interface that screenshot monitoring components need to implement
public protocol ScreenshotMonitorProtocol {
    /// Screenshot handler callback type
    typealias ScreenshotHandler = (URL) -> Void

    /// Monitoring status
    var isMonitoring: Bool { get }

    /// Get screenshot save location
    func getScreenshotLocation() -> String

    /// Start monitoring screenshots
    func startMonitoring() throws

    /// Stop monitoring screenshots
    func stopMonitoring()

    /// Set screenshot handler callback
    /// - Parameter handler: Callback function to process new screenshots
    func setScreenshotHandler(_ handler: @escaping ScreenshotHandler)
}

// MARK: - Screenshot Monitor Error Types

/// Screenshot Monitor Error Types
/// Defines errors that may occur during screenshot monitoring
public enum ScreenshotMonitorError: Error {
    /// Unable to get screenshot save directory
    case unableToGetScreenshotLocation
    /// Monitoring already started
    case monitoringAlreadyStarted
    /// Monitoring setup failed
    case monitoringSetupFailed(String)

    /// Error description
    public var localizedDescription: String {
        switch self {
        case .unableToGetScreenshotLocation:
            return "Unable to get screenshot save directory"
        case .monitoringAlreadyStarted:
            return "Screenshot monitoring already started"
        case .monitoringSetupFailed(let reason):
            return "Monitoring setup failed: \(reason)"
        }
    }
}

// MARK: - Default Screenshot Monitor Implementation

/// Default Screenshot Monitor Implementation
/// Uses NSMetadataQuery to monitor system screenshot folder
public final class ScreenshotMonitor: ScreenshotMonitorProtocol {
    private var metadataQuery: NSMetadataQuery?
    private var screenshotHandler: ScreenshotMonitorProtocol.ScreenshotHandler?
    private var screenshotLocationCache: String?

    /// Logger
    private let logger = Logger(subsystem: "com.snapsort.screenshot", category: "ScreenshotMonitor")

    /// Monitoring status
    public private(set) var isMonitoring: Bool = false

    public static let shared = ScreenshotMonitor()

    /// Initialization
    public init() {
        logger.debug("Screenshot monitor initialized")
    }

    deinit {
        stopMonitoring()
        logger.debug("Screenshot monitor deinitialized")
    }

    /// Get screenshot save location
    /// - Returns: Directory path where screenshots are saved
    public func getScreenshotLocation() -> String {
        if let cachedLocation = screenshotLocationCache {
            logger.debug("Using cached screenshot location: \(cachedLocation)")
            return cachedLocation
        }

        // TODO: In Sandbox, can't read defaults: See solution in Docs/SandboxApp读取defaults.md
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", "com.apple.screencapture", "location"]

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        do {
            logger.debug("Attempting to read system screenshot location")
            try process.run()
            process.waitUntilExit()

            // Check process exit status
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(
                    in: .whitespacesAndNewlines),
                    !output.isEmpty
                {
                    let expandedPath = (output as NSString).expandingTildeInPath
                    screenshotLocationCache = expandedPath
                    logger.info("Retrieved custom screenshot location: \(expandedPath)")
                    return expandedPath
                }
            }
            // Default settings don't exist or read failed, no need to handle error, use default path directly
            logger.notice("Could not retrieve custom screenshot location, using default path")
        } catch {
            // Catch exceptions but don't output error messages, use default path directly
            logger.error("Failed to execute defaults command: \(error.localizedDescription)")
        }

        // If custom location can't be retrieved, return desktop path as default
        let desktopPath = (NSHomeDirectory() as NSString).appendingPathComponent("Desktop")
        screenshotLocationCache = desktopPath
        logger.info("Using desktop as fallback screenshot location: \(desktopPath)")
        return desktopPath
    }

    /// Start monitoring screenshots
    /// - Throws: ScreenshotMonitorError if monitoring cannot be started
    public func startMonitoring() throws {
        guard !isMonitoring else {
            logger.notice("Monitoring already started, ignoring request")
            throw ScreenshotMonitorError.monitoringAlreadyStarted
        }

        let screenshotLocation = getScreenshotLocation()
        logger.info("Starting screenshot monitoring at location: \(screenshotLocation)")

        // Create and configure metadata query
        let query = NSMetadataQuery()
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture == 1")
        query.searchScopes = [screenshotLocation]

        // Register notification observers
        logger.debug("Registering notification observers for metadata query updates")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQueryUpdate(_:)),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQueryFinished(_:)),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )

        // Start query
        logger.debug("Attempting to start metadata query")
        if query.start() {
            metadataQuery = query
            isMonitoring = true
            logger.info("Screenshot monitoring successfully started")
        } else {
            logger.error("Failed to start metadata query")
            throw ScreenshotMonitorError.monitoringSetupFailed("Unable to start metadata query")
        }
    }

    /// Stop monitoring screenshots
    public func stopMonitoring() {
        guard isMonitoring, let query = metadataQuery else {
            logger.debug("Stop monitoring called but no active monitoring found")
            return
        }

        logger.info("Stopping screenshot monitoring")
        query.stop()
        NotificationCenter.default.removeObserver(
            self, name: .NSMetadataQueryDidUpdate, object: query)
        NotificationCenter.default.removeObserver(
            self, name: .NSMetadataQueryDidFinishGathering, object: query)

        metadataQuery = nil
        isMonitoring = false
        logger.info("Screenshot monitoring stopped")
    }

    /// Set screenshot handler callback
    /// - Parameter handler: Callback function to process new screenshots
    public func setScreenshotHandler(
        _ handler: @escaping ScreenshotMonitorProtocol.ScreenshotHandler
    ) {
        logger.debug("Setting new screenshot handler")
        self.screenshotHandler = handler
    }

    // MARK: - Private Methods

    @objc private func handleQueryUpdate(_ notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery else {
            logger.error("Received query update notification with invalid object")
            return
        }

        query.disableUpdates()

        // Get newly added items
        if let addedItems = notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey]
            as? [NSMetadataItem]
        {
            logger.info("Query update detected \(addedItems.count) new screenshot(s)")
            processNewScreenshots(addedItems)
        }

        query.enableUpdates()
    }

    @objc private func handleQueryFinished(_ notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery else {
            logger.error("Received query finished notification with invalid object")
            return
        }

        // Start monitoring for changes
        logger.debug("Initial query finished, enabling updates for continuous monitoring")
        query.enableUpdates()
    }

    private func processNewScreenshots(_ items: [NSMetadataItem]) {
        for item in items {
            guard let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else {
                logger.warning("Received metadata item without valid path")
                continue
            }
            let url = URL(fileURLWithPath: path)
            logger.info("Processing new screenshot: \(url.lastPathComponent)")

            // Call handler callback
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if let handler = self.screenshotHandler {
                    self.logger.debug("Calling screenshot handler for: \(url.lastPathComponent)")
                    handler(url)
                } else {
                    self.logger.notice(
                        "No screenshot handler registered to process: \(url.lastPathComponent)")
                }
            }
        }
    }
}
