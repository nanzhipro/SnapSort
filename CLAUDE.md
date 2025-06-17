# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SnapSort is an intelligent screenshot management application for macOS. It automatically monitors system screenshots, performs OCR text recognition, uses AI for classification, and organizes screenshots into categorized folders.

## Project Structure

- **SnapSort/App/**: Main application entry point and AppDelegate
- **SnapSort/Services/**: Core business logic services
  - `ServiceManager.swift`: Central coordinator managing all services
  - `ScreenshotMonitor/`: Monitors screenshot creation using NSMetadataQuery
  - `QuestOCR/`: OCR text recognition using Vision framework
  - `AIClassifier/`: AI-powered classification using OpenAI compatible APIs
  - `FileOrganizer/`: File management and organization
  - `DatabaseManager/`: SQLite database operations
  - `Notifications/`: System notification management
- **SnapSort/Views/**: SwiftUI views organized by feature
  - `Settings/`: Application settings interface
  - `Components/`: Reusable UI components
- **SnapSort/ViewModels/**: MVVM view models
- **SnapSort/Models/**: Data models and structures
- **SnapSort/Resources/**: Assets, localization files

## Development Commands

### Building
```bash
# Build the project
xcodebuild build -project SnapSort.xcodeproj -scheme SnapSort -configuration Release

# Clean build artifacts
xcodebuild clean -project SnapSort.xcodeproj -scheme SnapSort -configuration Release
```

### Testing
```bash
# Run unit tests
xcodebuild test -project SnapSort.xcodeproj -scheme SnapSort -destination 'platform=macOS'

# Run specific test class
xcodebuild test -project SnapSort.xcodeproj -scheme SnapSort -destination 'platform=macOS' -only-testing:SnapSortTests/SnapSortTests
```

### Release Build
```bash
# Build production release with notarization (requires .env configuration)
./build.sh
```

## Architecture

### Service-Oriented Architecture
The application follows a service-oriented architecture coordinated by `ServiceManager`:

1. **Screenshot Detection**: `ScreenshotMonitor` uses NSMetadataQuery to detect new screenshots
2. **OCR Processing**: `QuestOCR` extracts text using Vision framework
3. **AI Classification**: `AIClassifier` categorizes content using OpenAI-compatible APIs
4. **File Organization**: `FileOrganizer` moves screenshots to appropriate folders
5. **Database Management**: `DatabaseManager` stores metadata and search indices
6. **User Notifications**: `NotificationManager` provides feedback to users

### Key Dependencies
- **OpenAI**: AI classification via OpenAI-compatible APIs (DeepSeek, etc.)
- **SQLite.swift**: Database operations
- **Settings**: macOS settings UI framework
- **LaunchAtLogin**: Auto-launch functionality

### Threading Model
- Main thread: UI updates and NSMetadataQuery operations
- Background queues: OCR processing, AI classification, file operations
- Async/await: Modern concurrency for service coordination

## Configuration

### Environment Variables (.env file required for building)
```bash
APPLE_ID=your.email@example.com
APPLE_PASSWORD=app-specific-password
TEAM_ID=XXXXXXXXXX
```

### User Preferences (UserDefaults keys)
- `ai_api_host`: AI service endpoint (default: "https://api.deepseek.com")
- `ai_api_key_data`: Encrypted API key data
- `enableAIClassification`: AI classification toggle
- `user_categories`: User-defined categories (JSON)

## Development Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use swift-format for code formatting
- Modern Swift 6.0+ patterns with async/await
- SwiftUI-first approach over AppKit when possible

### File Organization
- New components go in `Views/Components/`
- ViewModels in `ViewModels/`
- Models in `Models/`
- Services maintain single responsibility principle

### Localization
- Support for Chinese, English, and Japanese
- Localization files in `Resources/Localization/`
- Use LocalizedStringKey for all user-facing strings

### Testing Strategy
- Unit tests for service layer logic
- Integration tests for service coordination
- UI tests for critical user workflows
- Mock external dependencies (AI APIs, file system)

## Common Development Tasks

### Adding New Classification Categories
1. Update `CategoryModels.swift` data structures
2. Modify `DatabaseManager` schema if needed
3. Update `CategoriesViewModel` and `CategoriesView`
4. Test category creation and AI classification

### Extending OCR Language Support
1. Add language enum to `OCRLanguage.swift`
2. Update `OCRProcessor` language configuration
3. Add localization support for new language
4. Test recognition accuracy with sample images

### Integrating New AI Providers
1. Implement `OpenAIProtocol` for new provider
2. Update `AIClassifierFactory` 
3. Add provider-specific configuration options
4. Test classification accuracy and error handling

## Debugging

### Common Issues
- **Screenshot monitoring not working**: Check file system permissions and NSMetadataQuery scope
- **OCR recognition poor**: Verify image quality and Vision framework language configuration
- **AI classification errors**: Check API credentials and network connectivity
- **File organization failures**: Verify directory permissions and disk space

### Logging
- Use structured logging with os.log framework
- Service-specific log categories for filtering
- Debug builds include verbose logging

## System Requirements

- macOS 15+
- Xcode 16+
- Swift 6.0+
- Apple Silicon or Intel processor
- Requires permissions: Files and Folders, Notifications

## Release Process

1. Update version in Info.plist
2. Test all functionality thoroughly
3. Configure .env file with Apple ID credentials
4. Run `./build.sh` for notarized release
5. Update brew formula in `brew/snapsort.rb`
6. Tag release and update documentation