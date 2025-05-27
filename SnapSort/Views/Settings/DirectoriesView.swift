//
//  DirectoriesView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// 目录设置视图
///
/// 提供截图文件的高级目录管理选项。
/// 采用标准macOS设置页面风格，使用Form布局确保用户能够轻松管理文件存储策略。
/// 基础存储位置设置已移至通用设置页面。
struct DirectoriesView: View {

    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text(LocalizedStringKey("directories.advancedTitle"))
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(LocalizedStringKey("directories.movedNotice"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DirectoriesView()
        .frame(width: 500, height: 400)
}
