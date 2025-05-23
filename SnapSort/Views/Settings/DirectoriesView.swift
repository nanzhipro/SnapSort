//
//  DirectoriesView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// 目录设置视图
///
/// 管理截图文件的存储位置和组织方式设置。提供基础目录选择、
/// 子文件夹创建选项、文件名保留规则等配置功能。
/// 采用直观的表单布局，确保用户能够轻松管理文件存储策略。
struct DirectoriesView: View {

    /// 设置视图模型引用
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            storageLocationSection
            organizationOptionsSection
        }
        .padding()
    }
}

// MARK: - View Components

extension DirectoriesView {

    /// 存储位置设置区域
    @ViewBuilder
    fileprivate var storageLocationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                currentDirectoryDisplay
                directorySelectionButton
            }
        } header: {
            Text(LocalizedStringKey("settings.directories.storage"))
        }
    }

    /// 当前目录显示
    @ViewBuilder
    fileprivate var currentDirectoryDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedStringKey("settings.directories.current"))
                    .font(.headline)
                Spacer()
            }

            Text(currentDirectoryText)
                .font(.body)
                .foregroundColor(directoryTextColor)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }

    /// 目录选择按钮
    @ViewBuilder
    fileprivate var directorySelectionButton: some View {
        Button(LocalizedStringKey("settings.directories.select")) {
            viewModel.selectBaseDirectory()
        }
        .buttonStyle(.borderedProminent)
    }

    /// 组织选项设置区域
    @ViewBuilder
    fileprivate var organizationOptionsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                subfolderToggle
                filenameToggle
                fileSizeLimit
            }
        } header: {
            Text(LocalizedStringKey("settings.directories.options"))
        }
    }

    /// 子文件夹创建选项
    @ViewBuilder
    fileprivate var subfolderToggle: some View {
        Toggle(
            LocalizedStringKey("settings.directories.createSubfolders"),
            isOn: $viewModel.storageSettings.createSubfolders
        )
    }

    /// 文件名保留选项
    @ViewBuilder
    fileprivate var filenameToggle: some View {
        Toggle(
            LocalizedStringKey("settings.directories.preserveFilenames"),
            isOn: $viewModel.storageSettings.preserveOriginalFilenames
        )
    }

    /// 文件大小限制设置
    @ViewBuilder
    fileprivate var fileSizeLimit: some View {
        HStack {
            Text(LocalizedStringKey("settings.directories.maxFileSize"))

            Spacer()

            HStack(spacing: 8) {
                TextField(
                    "50",
                    value: $viewModel.storageSettings.maxFileSize,
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)

                Text("MB")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Computed Properties

extension DirectoriesView {

    /// 当前目录显示文本
    fileprivate var currentDirectoryText: String {
        if viewModel.storageSettings.baseDirectory.isEmpty {
            return NSLocalizedString("settings.directories.notSelected", comment: "未选择")
        } else {
            return viewModel.storageSettings.baseDirectory
        }
    }

    /// 目录文本颜色
    fileprivate var directoryTextColor: Color {
        viewModel.storageSettings.baseDirectory.isEmpty ? .secondary : .primary
    }
}

#Preview {
    DirectoriesView(viewModel: SettingsViewModel())
        .frame(width: 500, height: 400)
}
