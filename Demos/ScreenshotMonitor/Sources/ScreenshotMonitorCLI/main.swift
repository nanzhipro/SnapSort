//
//  main.swift
//  ScreenshotMonitorCLI
//
//  Created by CursorAI on 2024-05-22.
//

import ArgumentParser
import Foundation
import ScreenshotMonitor

/// 截图监控命令行应用
struct ScreenshotMonitorCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "screenshot-monitor",
        abstract: "监控系统截图并处理",
        discussion: "启动一个守护进程来监控系统截图，检测到新截图时执行相应操作"
    )

    /// 允许用户指定输出模式
    @Flag(name: .shortAndLong, help: "使用详细输出模式")
    var verbose: Bool = false

    /// 是否打印截图路径
    @Flag(name: .shortAndLong, help: "仅打印截图路径而不处理")
    var printOnly: Bool = false

    func run() throws {
        // 创建截图监控器
        let monitor = DefaultScreenshotMonitor()

        if verbose {
            print("截图保存位置: \(monitor.getScreenshotLocation())")
            print("开始监控截图...")
        } else {
            print("ScreenshotMonitor 已启动")
        }

        // 设置截图处理回调
        monitor.setScreenshotHandler { url in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestamp = dateFormatter.string(from: Date())

            if self.printOnly {
                print("\(timestamp) - 新截图: \(url.path)")
            } else {
                print("\(timestamp) - 检测到新截图: \(url.path)")
                // 这里可以添加其他处理逻辑
            }
        }

        // 启动监控
        try monitor.startMonitoring()

        // 保持程序运行，直到用户取消
        RunLoop.main.run()
    }
}

// 启动命令行应用
ScreenshotMonitorCommand.main()
