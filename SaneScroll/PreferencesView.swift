//
//  PreferencesView.swift
//  SaneScroll
//

import SwiftUI

struct PreferencesView: View {
    @StateObject private var viewModel = SettingsViewModel()
    var onDismiss: ((Bool) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Toggle("Invert vertical scrolling", isOn: $viewModel.invertVerticalScroll)
                    Toggle("Invert horizontal scrolling", isOn: $viewModel.invertHorizontalScroll)
                } header: {
                    Text("Scroll Direction")
                }

                Section {
                    Toggle("Disable scroll acceleration", isOn: $viewModel.disableScrollAccel)
                    Stepper(value: $viewModel.scrollLines, in: 1...99) {
                        HStack {
                            Text("Lines per scroll")
                            Spacer()
                            Text("\(viewModel.scrollLines)")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text("Scroll Behavior")
                }

                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Toggle("Disable mouse acceleration", isOn: $viewModel.disableMouseAccel)
                        Text("1:1 mouse/cursor movement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Mouse")
                }

                Section {
                    Toggle("Launch at login", isOn: $viewModel.launchAtLogin)

                    VStack(alignment: .leading, spacing: 2) {
                        Toggle("Show menu bar icon", isOn: $viewModel.showMenuBarIcon)
                        Text("If disabled, open the app from Finder to show preferences")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Toggle("Alternate detection method", isOn: $viewModel.alternateDetectionMethod)
                        Text("Enable if scrolling isn't being inverted as expected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("General")
                }
            }
            .groupedFormStyle()

            Divider()

            HStack {
                Button("Help") {
                    if let url = URL(string: "https://github.com/dyarfaradj/SaneScroll/blob/main/README.md") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Button("Sponsor") {
                    if let url = URL(string: "https://github.com/sponsors/dyarfaradj") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Spacer()

                Button("Cancel") {
                    onDismiss?(false)
                }
                .keyboardShortcut(.cancelAction)

                Button("OK") {
                    viewModel.apply()
                    onDismiss?(true)
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 420)
    }
}

private extension View {
    @ViewBuilder
    func groupedFormStyle() -> some View {
        if #available(macOS 13.0, *) {
            self.formStyle(.grouped)
        } else {
            self
        }
    }
}
