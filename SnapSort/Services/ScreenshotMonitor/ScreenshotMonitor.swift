//
//  ScreenshotMonitor.swift
//  ScreenshotMonitor
//
//  Created by CursorAI on 2024-05-22.
//

import Foundation
import os

// MARK: - 截图监控协议

/// 截图监控协议
/// 定义了截图监控组件需要实现的基本功能接口
public protocol ScreenshotMonitorProtocol {
    /// 截图处理回调类型
    typealias ScreenshotHandler = (URL) -> Void

    /// 监控状态
    var isMonitoring: Bool { get }

    /// 获取截图保存位置
    func getScreenshotLocation() -> String

    /// 开始监控截图
    func startMonitoring() throws

    /// 停止监控截图
    func stopMonitoring()

    /// 设置截图处理回调
    /// - Parameter handler: 处理新截图的回调函数
    func setScreenshotHandler(_ handler: @escaping ScreenshotHandler)
}

// MARK: - 截图监控错误类型

/// 截图监控错误类型
/// 定义了截图监控过程中可能出现的错误
public enum ScreenshotMonitorError: Error {
    /// 无法获取截图保存目录
    case unableToGetScreenshotLocation
    /// 监控已经启动
    case monitoringAlreadyStarted
    /// 监控设置失败
    case monitoringSetupFailed(String)

    /// 错误描述
    public var localizedDescription: String {
        switch self {
        case .unableToGetScreenshotLocation:
            return "无法获取截图保存目录"
        case .monitoringAlreadyStarted:
            return "截图监控已经启动"
        case .monitoringSetupFailed(let reason):
            return "监控设置失败: \(reason)"
        }
    }
}

// MARK: - 默认截图监控实现

/// 默认截图监控实现
/// 使用 NSMetadataQuery 监控系统截图文件夹
public final class ScreenshotMonitor: ScreenshotMonitorProtocol {
    private var metadataQuery: NSMetadataQuery?
    private var screenshotHandler: ScreenshotMonitorProtocol.ScreenshotHandler?
    private var screenshotLocationCache: String?

    /// 日志记录器
    private let logger = Logger(subsystem: "com.snapsort.screenshot", category: "ScreenshotMonitor")

    /// 监控状态
    public private(set) var isMonitoring: Bool = false

    public static let shared = ScreenshotMonitor()

    /// 初始化
    public init() {
        logger.debug("Screenshot monitor initialized")
    }

    deinit {
        stopMonitoring()
        logger.debug("Screenshot monitor deinitialized")
    }

    /// 获取截图保存位置
    /// - Returns: 截图保存的目录路径
    public func getScreenshotLocation() -> String {
        if let cachedLocation = screenshotLocationCache {
            logger.debug("Using cached screenshot location: \(cachedLocation)")
            return cachedLocation
        }

        // TODO: Sandbox下，无法读取defaults： 方案见： Docs/SandboxApp读取defaults.md
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

            // 检查进程退出状态
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
            // 默认设置不存在或读取失败，无需处理错误，直接使用默认路径
            logger.notice("Could not retrieve custom screenshot location, using default path")
        } catch {
            // 捕获异常但不输出错误信息，直接使用默认路径
            logger.error("Failed to execute defaults command: \(error.localizedDescription)")
        }

        // 如果无法获取自定义位置，默认返回桌面路径
        let desktopPath = (NSHomeDirectory() as NSString).appendingPathComponent("Desktop")
        screenshotLocationCache = desktopPath
        logger.info("Using desktop as fallback screenshot location: \(desktopPath)")
        return desktopPath
    }

    /// 开始监控截图
    /// - Throws: ScreenshotMonitorError 如果监控无法启动
    public func startMonitoring() throws {
        guard !isMonitoring else {
            logger.notice("Monitoring already started, ignoring request")
            throw ScreenshotMonitorError.monitoringAlreadyStarted
        }

        let screenshotLocation = getScreenshotLocation()
        logger.info("Starting screenshot monitoring at location: \(screenshotLocation)")

        // 创建并配置元数据查询
        let query = NSMetadataQuery()
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture == 1")
        query.searchScopes = [screenshotLocation]

        // 注册通知观察者
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

        // 启动查询
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

    /// 停止监控截图
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

    /// 设置截图处理回调
    /// - Parameter handler: 处理新截图的回调函数
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

        // 获取新添加的项目
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

        // 开始监控变化
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

            // 调用处理回调
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
