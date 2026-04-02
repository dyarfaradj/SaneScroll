//
//  AboutView.swift
//  SaneScroll
//

import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    private var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? ""
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 4)

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("SaneScroll")
                .font(.title)
                .fontWeight(.semibold)

            Text("Version \(appVersion) (\(buildNumber))")
                .font(.callout)
                .foregroundColor(.secondary)

            Text("Separate scroll direction for your\nmouse and trackpad.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Text(copyright)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button("GitHub") {
                    if let url = URL(string: "https://github.com/dyarfaradj/SaneScroll") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Button("Sponsor") {
                    if let url = URL(string: "https://github.com/sponsors/dyarfaradj") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            VStack(spacing: 2) {
                Text("Originally created by Theron Tjapkes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Licensed under GPL-3.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer().frame(height: 4)
        }
        .padding(.horizontal, 32)
        .frame(width: 320)
    }
}
