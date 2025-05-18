//
//  FileSystemLogger.swift
//  SnapSort
//
//  Created by CursorAI on 2024-05-18.
//

import Foundation
import os.log

/// 文件系统操作日志记录器
///
/// 提供专门用于记录文件系统操作的日志功能，包括不同级别的日志记录以及格式化输出。
/// 使用 OSLog 确保日志记录高效且集成到系统日志中。
public struct FileSystemLogger {
    /// 日志子系统标识符
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.snapsort.filesystem"

    /// 日志类别
    private let category: String

    /// 日志记录器实例
    private let logger: OSLog

    /// 初始化文件系统日志记录器
    ///
    /// - Parameter category: 日志类别，用于区分不同组件的日志
    public init(category: String) {
        self.category = category
        self.logger = OSLog(subsystem: subsystem, category: category)
    }

    /// 记录调试级别的日志
    ///
    /// - Parameters:
    ///   - message: 日志消息文本
    ///   - function: 调用函数名（自动获取）
    ///   - line: 调用行号（自动获取）
    public func debug(_ message: String, function: String = #function, line: Int = #line) {
        let formattedMessage = formatMessage(message, function: function, line: line)
        os_log("%{public}@", log: logger, type: .debug, formattedMessage)
    }

    /// 记录信息级别的日志
    ///
    /// - Parameters:
    ///   - message: 日志消息文本
    ///   - function: 调用函数名（自动获取）
    ///   - line: 调用行号（自动获取）
    public func info(_ message: String, function: String = #function, line: Int = #line) {
        let formattedMessage = formatMessage(message, function: function, line: line)
        os_log("%{public}@", log: logger, type: .info, formattedMessage)
    }

    /// 记录错误级别的日志
    ///
    /// - Parameters:
    ///   - message: 日志消息文本
    ///   - error: 相关错误对象（可选）
    ///   - function: 调用函数名（自动获取）
    ///   - line: 调用行号（自动获取）
    public func error(
        _ message: String, error: Error? = nil, function: String = #function, line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        let formattedMessage = formatMessage(fullMessage, function: function, line: line)
        os_log("%{public}@", log: logger, type: .error, formattedMessage)
    }

    /// 格式化日志消息，添加时间戳和调用信息
    ///
    /// - Parameters:
    ///   - message: 原始日志消息
    ///   - function: 调用函数名
    ///   - line: 调用行号
    /// - Returns: 格式化后的日志消息
    private func formatMessage(_ message: String, function: String, line: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        return "[\(timestamp)] [\(category)] [\(function):\(line)] \(message)"
    }
}
