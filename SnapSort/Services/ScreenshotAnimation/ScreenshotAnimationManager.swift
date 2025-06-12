//
//  ScreenshotAnimationManager.swift
//  SnapSort
//
//  Created by CursorAI on 2024-08-07.
//

import AppKit
import Combine
import Foundation
import SwiftUI

/// Screenshot Animation Manager
/// Manages the lifecycle and state of the screenshot processing animation
///
/// This class provides a centralized way to coordinate animation states that reflect
/// the various stages of screenshot processing, from initial capture through classification.
public final class ScreenshotAnimationManager: ObservableObject {

    // MARK: - Published Properties

    /// Current animation state
    @Published public private(set) var state: AnimationState = .idle

    /// Screenshot being processed
    @Published public private(set) var screenshot: NSImage?

    /// Category assigned to the screenshot
    @Published public private(set) var category: String?

    // MARK: - Private Properties

    /// Animation window controller
    private var windowController: NSWindowController?

    /// Singleton instance
    public static let shared = ScreenshotAnimationManager()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Start the animation sequence for a new screenshot
    /// - Parameter screenshotURL: URL of the screenshot file
    public func startAnimation(for screenshotURL: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Load screenshot image
            if let image = NSImage(contentsOf: screenshotURL) {
                self.screenshot = image
                self.state = .started

                // Create and show animation window
                if self.windowController == nil {
                    let contentView = self.animationContentView()
                    let hostingController = NSHostingController(rootView: contentView)

                    let window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 60, height: 60),
                        styleMask: [.borderless],
                        backing: .buffered,
                        defer: false
                    )

                    // Position in top-right corner with margin
                    if let screen = NSScreen.main {
                        let screenRect = screen.visibleFrame
                        let windowSize = window.frame.size
                        let x = screenRect.maxX - windowSize.width - 20
                        let y = screenRect.maxY - windowSize.height - 20
                        window.setFrameOrigin(NSPoint(x: x, y: y))
                    } else {
                        window.center()
                    }

                    window.contentView = hostingController.view
                    window.backgroundColor = NSColor.clear
                    window.isOpaque = false
                    window.level = .floating
                    window.hasShadow = false
                    window.alphaValue = 0
                    window.isMovableByWindowBackground = true

                    self.windowController = NSWindowController(window: window)
                }

                self.windowController?.showWindow(nil)

                // Fade in window
                if let window = self.windowController?.window {
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.3
                        window.animator().alphaValue = 1
                    }
                }
            }
        }
    }

    /// Creates the animation content view
    private func animationContentView() -> some View {
        AnimationContentView(manager: self)
    }

    /// Content view for the animation
    private struct AnimationContentView: View {
        @ObservedObject var manager: ScreenshotAnimationManager
        @State private var opacity: Double = 0

        var body: some View {
            Group {
                switch manager.state {
                case .idle:
                    EmptyView()
                case .started:
                    StartedAnimationView()
                case .classifying:
                    ClassifyingAnimationView()
                case .completed:
                    CompletedAnimationView()
                }
            }
            .frame(width: 60, height: 60)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 1
                }
            }
            .onChange(of: manager.state) { newState in
                if newState == .idle {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }

                    // Schedule actual window close after fade-out animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        manager.windowController?.close()
                    }
                }
            }
        }
    }

    // Animation views for each state

    private struct StartedAnimationView: View {
        var body: some View {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .opacity(0.7)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 32, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
                    .symbolEffect(.bounce.byLayer, options: .repeating)
            }
        }
    }

    private struct ClassifyingAnimationView: View {
        var body: some View {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .opacity(0.7)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 32, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                    .symbolEffect(.bounce.down.byLayer, options: .repeating)
            }
        }
    }

    private struct CompletedAnimationView: View {
        var body: some View {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .opacity(0.7)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce.up, options: .nonRepeating)
                    .symbolEffect(.pulse, options: .nonRepeating)
            }
        }
    }

    /// Update animation state to classification
    public func updateToClassifying() {
        DispatchQueue.main.async {
            self.state = .classifying
        }
    }

    /// Update animation state to completed and close
    /// - Parameter category: Category assigned to the screenshot
    public func updateToCompleted(category: String) {
        DispatchQueue.main.async {
            self.category = category
            self.state = .completed

            // Show completed animation for 1.5 seconds, then close
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.closeAnimation()
            }
        }
    }

    /// Update animation state to error and close
    /// - Parameter error: Error that occurred during processing
    public func updateToError(error: Error) {
        DispatchQueue.main.async {
            self.closeAnimation()
        }
    }

    /// Close the animation window
    public func closeAnimation() {
        DispatchQueue.main.async { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.state = .idle
            }

            // Clean up resources
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.screenshot = nil
                self?.category = nil
                self?.windowController = nil
            }
        }
    }
}

// MARK: - Animation State Enum

/// States representing the various stages of screenshot processing
public enum AnimationState {
    /// No active animation
    case idle
    /// Animation has started, showing initial state
    case started
    /// AI classification is in progress
    case classifying
    /// Processing completed successfully
    case completed
}
