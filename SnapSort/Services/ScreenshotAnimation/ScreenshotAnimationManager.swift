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
/// the various stages of screenshot processing, from initial capture through OCR,
/// classification, file organization, and database update.
public final class ScreenshotAnimationManager: ObservableObject {

    // MARK: - Published Properties

    /// Current animation state
    @Published public private(set) var state: AnimationState = .idle

    /// Screenshot being processed
    @Published public private(set) var screenshot: NSImage?

    /// Category assigned to the screenshot
    @Published public private(set) var category: String?

    /// Error that occurred during processing
    @Published public private(set) var error: Error?

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
                    // Create a SwiftUI view that shows processing state
                    let contentView = self.animationContentView()
                    let hostingController = NSHostingController(rootView: contentView)

                    let window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 140, height: 160),
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
        @State private var dragOffset = CGSize.zero
        @State private var opacity: Double = 0
        @State private var showCloseButton: Bool = false
        @State private var showText: Bool = true

        var body: some View {
            ZStack {
                // Very subtle background for better visibility
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 130, height: 150)
                    .blur(radius: 10)

                // Status animation with dynamic SF Symbol
                VStack(spacing: 8) {
                    Group {
                        switch manager.state {
                        case .idle:
                            EmptyView()
                        case .started:
                            StartedAnimationView()
                        case .ocrProcessing:
                            OCRAnimationView()
                        case .classifying:
                            ClassifyingAnimationView()
                        case .fileOrganizing:
                            FileOrganizingAnimationView()
                        case .databaseUpdating:
                            DatabaseAnimationView()
                        case .completed:
                            CompletedAnimationView(category: manager.category)
                        case .error:
                            ErrorAnimationView()
                        }
                    }
                    .frame(width: 120, height: 120)

                    // Status text
                    if showText && manager.state != .idle {
                        Text(manager.stateText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                                    .shadow(color: Color.black.opacity(0.2), radius: 3)
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // Close button
                if showCloseButton {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                manager.closeAnimation()
                            }) {
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(8)
                        }
                        Spacer()
                    }
                    .frame(width: 140, height: 160)
                }
            }
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
                        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }
                        ) {
                            window.close()
                        }
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }
                        ) {
                            let newPosition = NSPoint(
                                x: window.frame.origin.x + gesture.translation.width,
                                y: window.frame.origin.y - gesture.translation.height
                            )
                            window.setFrameOrigin(newPosition)
                        }
                    }
            )
            .contentShape(Rectangle())
            .onHover { isHovering in
                withAnimation {
                    showCloseButton = isHovering
                    showText = !isHovering || manager.state == .completed || manager.state == .error
                }
            }
        }
    }

    // Base animation view with common properties
    private struct BaseAnimationView: View {
        let symbolName: String
        let color: Color
        let animate: Bool

        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 110, height: 110)

                if animate {
                    SymbolEffectView(symbolName)
                        .font(.system(size: 45, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(color)
                        .symbolEffect(.bounce.byLayer, options: .repeating)
                        .symbolEffect(.pulse, options: .repeating)
                } else {
                    SymbolEffectView(symbolName)
                        .font(.system(size: 45, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(color)
                }
            }
        }
    }

    // Dynamic SF Symbol animation view
    private struct SymbolEffectView: View {
        let symbolName: String

        init(_ symbolName: String) {
            self.symbolName = symbolName
        }

        var body: some View {
            Image(systemName: symbolName)
        }
    }

    // Animation views for each state

    private struct StartedAnimationView: View {
        var body: some View {
            BaseAnimationView(
                symbolName: "photo.on.rectangle.angled",
                color: .blue,
                animate: true
            )
        }
    }

    private struct OCRAnimationView: View {
        @State private var isAnimating = false

        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 110, height: 110)

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 45, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                    .symbolEffect(.pulse.byLayer, options: .repeating)
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
            }
        }
    }

    private struct ClassifyingAnimationView: View {
        @State private var scale: CGFloat = 1.0

        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 110, height: 110)

                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 45, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce.down.byLayer, options: .repeating)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                    .scaleEffect(scale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            scale = 1.2
                        }
                    }
            }
        }
    }

    private struct FileOrganizingAnimationView: View {
        @State private var rotation: Double = 0

        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 110, height: 110)

                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 45, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                    .symbolEffect(.variableColor.cumulative, options: .repeating)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            }
        }
    }

    private struct DatabaseAnimationView: View {
        @State private var isAnimating = false

        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 110, height: 110)

                Image(systemName: "externaldrive.fill.badge.icloud")
                    .font(.system(size: 45, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                    .symbolEffect(.variableColor.reversing, options: .repeating)
                    .symbolEffect(.pulse, options: .repeating)
                    .offset(y: isAnimating ? -5 : 5)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
            }
        }
    }

    private struct CompletedAnimationView: View {
        let category: String?
        @State private var scale: CGFloat = 0
        @State private var showCategory: Bool = false

        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 110, height: 110)

                VStack(spacing: 5) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 45, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.green)
                        .scaleEffect(scale)

                    if let category = category, showCategory {
                        Text(category)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.3))
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        scale = 1
                    }

                    withAnimation(.easeIn.delay(0.7)) {
                        showCategory = true
                    }
                }
            }
        }
    }

    private struct ErrorAnimationView: View {
        @State private var shake = false

        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 110, height: 110)

                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 45, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.red)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                    .rotationEffect(.degrees(shake ? 15 : -15))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                            shake = true
                        }
                    }
            }
        }
    }

    /// Icon system name for the current state
    private var stateIconName: String {
        switch state {
        case .idle:
            return "photo"
        case .started:
            return "photo.on.rectangle.angled"
        case .ocrProcessing:
            return "doc.text.magnifyingglass"
        case .classifying:
            return "folder.badge.gearshape"
        case .fileOrganizing:
            return "doc.on.clipboard"
        case .databaseUpdating:
            return "externaldrive.fill.badge.icloud"
        case .completed:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    /// Icon representing the current processing state
    private var stateIcon: Image {
        switch state {
        case .idle:
            return Image(systemName: "photo")
        case .started:
            return Image(systemName: "photo.on.rectangle.angled")
        case .ocrProcessing:
            return Image(systemName: "doc.text.magnifyingglass")
        case .classifying:
            return Image(systemName: "folder.badge.gearshape")
        case .fileOrganizing:
            return Image(systemName: "doc.on.clipboard")
        case .databaseUpdating:
            return Image(systemName: "externaldrive.fill.badge.icloud")
        case .completed:
            return Image(systemName: "checkmark.circle")
        case .error:
            return Image(systemName: "exclamationmark.triangle")
        }
    }

    /// Text describing the current processing state
    private var stateText: String {
        switch state {
        case .idle:
            return NSLocalizedString("animation.state.idle", comment: "Animation state: idle")
        case .started:
            return NSLocalizedString("animation.state.started", comment: "Animation state: started")
        case .ocrProcessing:
            return NSLocalizedString(
                "animation.state.ocrProcessing", comment: "Animation state: OCR processing")
        case .classifying:
            return NSLocalizedString(
                "animation.state.classifying", comment: "Animation state: classifying")
        case .fileOrganizing:
            return NSLocalizedString(
                "animation.state.fileOrganizing", comment: "Animation state: file organizing")
        case .databaseUpdating:
            return NSLocalizedString(
                "animation.state.databaseUpdating", comment: "Animation state: database updating")
        case .completed:
            return NSLocalizedString(
                "animation.state.completed", comment: "Animation state: completed")
        case .error:
            return NSLocalizedString("animation.state.error", comment: "Animation state: error")
        }
    }

    /// Color representing the current processing state
    private var stateColor: Color {
        switch state {
        case .idle, .started:
            return Color.blue
        case .ocrProcessing, .classifying, .fileOrganizing, .databaseUpdating:
            return Color.orange
        case .completed:
            return Color.green
        case .error:
            return Color.red
        }
    }

    /// Determines if the icon should rotate
    private var shouldRotate: Bool {
        switch state {
        case .ocrProcessing, .classifying, .fileOrganizing, .databaseUpdating:
            return true
        default:
            return false
        }
    }

    /// Update animation state to OCR processing
    public func updateToOCRProcessing() {
        DispatchQueue.main.async {
            self.state = .ocrProcessing
        }
    }

    /// Update animation state to classification
    public func updateToClassifying() {
        DispatchQueue.main.async {
            self.state = .classifying
        }
    }

    /// Update animation state to file organization
    public func updateToFileOrganizing() {
        DispatchQueue.main.async {
            self.state = .fileOrganizing
        }
    }

    /// Update animation state to database update
    public func updateToDatabaseUpdating() {
        DispatchQueue.main.async {
            self.state = .databaseUpdating
        }
    }

    /// Update animation state to completed
    /// - Parameter category: Category assigned to the screenshot
    public func updateToCompleted(category: String) {
        DispatchQueue.main.async {
            self.category = category
            self.state = .completed

            // Schedule window close after showing completion state
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.closeAnimation()
            }
        }
    }

    /// Update animation state to error
    /// - Parameter error: Error that occurred during processing
    public func updateToError(error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.state = .error

            // Schedule window close after showing error state
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.closeAnimation()
            }
        }
    }

    /// Close the animation window
    public func closeAnimation() {
        DispatchQueue.main.async { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.state = .idle
            }

            // The actual window closing is handled in the AnimationContentView's onChange
            // for the state transition to .idle

            // Clean up resources
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.screenshot = nil
                self?.category = nil
                self?.error = nil
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
    /// OCR text recognition is in progress
    case ocrProcessing
    /// AI classification is in progress
    case classifying
    /// File organization is in progress
    case fileOrganizing
    /// Database update is in progress
    case databaseUpdating
    /// Processing completed successfully
    case completed
    /// An error occurred during processing
    case error
}
