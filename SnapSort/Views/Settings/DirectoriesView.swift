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
/// 采用标准macOS设置页面风格，使用Form布局确保用户能够轻松管理文件存储策略。
struct DirectoriesView: View {

    @AppStorage("baseDirectory") private var baseDirectory: String = ""
    @AppStorage("createSubfolders") private var createSubfolders: Bool = true
    @AppStorage("preserveFilenames") private var preserveFilenames: Bool = true
    @AppStorage("maxFileSize") private var maxFileSize: Int = 50

    var body: some View {
        Form {
            Section("存储位置") {
                HStack {
                    Text("当前目录:")
                    Spacer()
                    Text(baseDirectory.isEmpty ? "未选择" : baseDirectory)
                        .foregroundColor(baseDirectory.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Button("选择目录...") {
                    selectDirectory()
                }
            }

            Section("组织选项") {
                Toggle("创建子文件夹", isOn: $createSubfolders)
                    .help("为每个分类创建单独的子文件夹")

                Toggle("保留原始文件名", isOn: $preserveFilenames)
                    .help("保持截图的原始文件名，否则使用时间戳命名")

                HStack {
                    Text("最大文件大小:")
                    Spacer()
                    TextField("50", value: $maxFileSize, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("MB")
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "选择截图分类保存的基础目录"

        if panel.runModal() == .OK {
            if let selectedURL = panel.url {
                baseDirectory = selectedURL.path
            }
        }
    }
}

#Preview {
    DirectoriesView()
        .frame(width: 500, height: 400)
}
