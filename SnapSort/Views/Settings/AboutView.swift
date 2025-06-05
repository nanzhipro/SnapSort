//
//  AboutView.swift
//  SnapSort
//
//  Created by CursorAI on 2025/1/4.
//

import SwiftUI

/// About View
///
/// Displays version information and developer information for the application.
/// Uses standard macOS settings page style, providing clear application information display.
struct AboutView: View {

    private let appVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)

                    Text("SnapSort")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(LocalizedStringKey("about.appDescription"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section(LocalizedStringKey("about.versionInfo")) {
                HStack {
                    Text(LocalizedStringKey("about.version"))
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(LocalizedStringKey("about.buildNumber"))
                    Spacer()
                    Text(buildNumber)
                        .foregroundColor(.secondary)
                }
            }

            Section(LocalizedStringKey("about.developer")) {
                HStack {
                    Text(LocalizedStringKey("about.developer"))
                    Spacer()
                    Text(LocalizedStringKey("about.developerName"))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(LocalizedStringKey("about.copyright"))
                    Spacer()
                    Text(LocalizedStringKey("about.copyrightText"))
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AboutView()
        .frame(width: 500, height: 400)
}
