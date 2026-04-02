//
//  SettingsViewModel.swift
//  SaneScroll
//

import Cocoa
import ServiceManagement

class SettingsViewModel: ObservableObject {
    @Published var invertVerticalScroll: Bool
    @Published var invertHorizontalScroll: Bool
    @Published var disableScrollAccel: Bool
    @Published var scrollLines: Int
    @Published var disableMouseAccel: Bool
    @Published var launchAtLogin: Bool
    @Published var showMenuBarIcon: Bool
    @Published var alternateDetectionMethod: Bool

    init() {
        let opts = Options.shared
        invertVerticalScroll = opts.invertVerticalScroll
        invertHorizontalScroll = opts.invertHorizontalScroll
        disableScrollAccel = opts.disableScrollAccel
        scrollLines = Int(opts.scrollLines)
        disableMouseAccel = opts.disableMouseAccel
        launchAtLogin = opts.launchAtLogin
        showMenuBarIcon = opts.showMenuBarIcon
        alternateDetectionMethod = opts.alternateDetectionMethod
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
        SMLoginItemSetEnabled("com.AutoLauncher" as CFString, launchAtLogin)

        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.disableMouseAccel()
        }
    }
}
