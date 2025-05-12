//
//  ScreenshotMonitorTests.swift
//  ScreenshotMonitorTests
//
//  Created by CursorAI on 2024-05-22.
//

import XCTest

@testable import ScreenshotMonitor

final class ScreenshotMonitorTests: XCTestCase {
    func testGetScreenshotLocation() {
        let monitor = DefaultScreenshotMonitor()
        let location = monitor.getScreenshotLocation()

        XCTAssertFalse(location.isEmpty, "截图位置不应为空")
        XCTAssertTrue(FileManager.default.fileExists(atPath: location), "截图位置应存在")
    }
}
