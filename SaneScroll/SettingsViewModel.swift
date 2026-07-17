//
//  SettingsViewModel.swift
//  SaneScroll
//

import Cocoa
import ServiceManagement

enum LoginItem {
    // Pre-rename helper id, cleaned up on every change so stale
    // registrations from old versions don't linger.
    private static let legacyHelperID = "com.AutoLauncher"
    private static let helperID = "com.dyarfaradj.SaneScroll.AutoLauncher"

    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return UserDefaults.standard.bool(forKey: "LaunchAtLogin")
    }

    static func setEnabled(_ enabled: Bool) {
        SMLoginItemSetEnabled(legacyHelperID as CFString, false)
        if #available(macOS 13.0, *) {
            SMLoginItemSetEnabled(helperID as CFString, false)
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("SaneScroll: failed to update login item: %@", error.localizedDescription)
            }
        } else {
            SMLoginItemSetEnabled(helperID as CFString, enabled)
        }
    }
}

class SettingsViewModel: ObservableObject {
    @Published var invertVerticalScroll: Bool
    @Published var invertHorizontalScroll: Bool
    @Published var disableScrollAccel: Bool
    @Published var scrollLines: Int
    @Published var disableMouseAccel: Bool
    @Published var launchAtLogin: Bool
    @Published var showMenuBarIcon: Bool
    @Published var alternateDetectionMethod: Bool

    private var optionsObserver: NSObjectProtocol?

    init() {
        let opts = Options.shared
        invertVerticalScroll = opts.invertVerticalScroll
        invertHorizontalScroll = opts.invertHorizontalScroll
        disableScrollAccel = opts.disableScrollAccel
        scrollLines = Int(opts.scrollLines)
        disableMouseAccel = opts.disableMouseAccel
        launchAtLogin = LoginItem.isEnabled
        showMenuBarIcon = opts.showMenuBarIcon
        alternateDetectionMethod = opts.alternateDetectionMethod

        // Keep an open preferences window in sync with the menu bar quick
        // toggles, so pressing OK doesn't write stale values back.
        optionsObserver = NotificationCenter.default.addObserver(
            forName: .saneScrollOptionsChanged, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let opts = Options.shared
            self.invertVerticalScroll = opts.invertVerticalScroll
            self.invertHorizontalScroll = opts.invertHorizontalScroll
            self.disableScrollAccel = opts.disableScrollAccel
            self.disableMouseAccel = opts.disableMouseAccel
        }
    }

    deinit {
        if let observer = optionsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func apply() {
        let defaults = UserDefaults.standard
        defaults.set(invertVerticalScroll, forKey: "InvertVerticalScroll")
        defaults.set(invertHorizontalScroll, forKey: "InvertHorizontalScroll")
        defaults.set(disableScrollAccel, forKey: "DisableScrollAccel")
        defaults.set(scrollLines, forKey: "ScrollLines")
        defaults.set(disableMouseAccel, forKey: "DisableMouseAccel")
        defaults.set(launchAtLogin, forKey: "LaunchAtLogin")
        defaults.set(showMenuBarIcon, forKey: "ShowMenuBarIcon")
        defaults.set(alternateDetectionMethod, forKey: "AlternateDetectionMethod")

        Options.shared.loadOptions()
        MenuBarItem.shared.refreshVisibility()
        LoginItem.setEnabled(launchAtLogin)

        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.disableMouseAccel()
        }
    }
}
