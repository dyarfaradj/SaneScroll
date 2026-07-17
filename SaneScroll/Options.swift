//
//  Options.swift
//  SaneScroll
//
//  Created by Theron Tjapkes on 7/25/20.
//  Copyright © 2020 Theron Tjapkes. All rights reserved.
//
import Cocoa
import Foundation

extension Notification.Name {
    // Posted when options are changed outside the preferences window
    // (e.g. the menu bar quick toggles).
    static let saneScrollOptionsChanged = Notification.Name("SaneScrollOptionsChanged")
}

class Options {
    static let shared = Options()
    var origAccel: Int32 = 45056
    var accel: Int32 = -1
    var showMenuBarIcon: Bool = true
    var invertVerticalScroll: Bool = true
    var invertHorizontalScroll: Bool = false
    var disableScrollAccel: Bool = true
    var scrollLines: Int64 = 3
    var alternateDetectionMethod: Bool = false
    var disableMouseAccel: Bool = false
    var launchAtLogin: Bool = false
    // Bundle identifiers of apps whose scrolling is left untouched
    var excludedApps: [String] = []
    var checkForUpdates: Bool = true

    init() {
        UserDefaults.standard.register(defaults: [
            "ShowMenuBarIcon": showMenuBarIcon,
            "InvertVerticalScroll": invertVerticalScroll,
            "InvertHorizontalScroll": invertHorizontalScroll,
            "DisableScrollAccel": disableScrollAccel,
            "ScrollLines": Int(scrollLines),
            "AlternateDetectionMethod": alternateDetectionMethod,
            "DisableMouseAccel": disableMouseAccel,
            "OriginalAccel": Int(origAccel),
            "LaunchAtLogin": launchAtLogin,
            "ExcludedApps": excludedApps,
            "CheckForUpdates": checkForUpdates,
        ])
        loadOptions()
    }

    func loadOptions() {
        showMenuBarIcon = UserDefaults.standard.bool(forKey: "ShowMenuBarIcon")
        invertVerticalScroll = UserDefaults.standard.bool(forKey: "InvertVerticalScroll")
        invertHorizontalScroll = UserDefaults.standard.bool(forKey: "InvertHorizontalScroll")
        disableScrollAccel = UserDefaults.standard.bool(forKey: "DisableScrollAccel")
        // Clamp to the range the UI allows; a zero or negative value written
        // directly to defaults would zero out every scroll delta.
        scrollLines = Int64(min(max(UserDefaults.standard.integer(forKey: "ScrollLines"), 1), 99))
        alternateDetectionMethod = UserDefaults.standard.bool(forKey: "AlternateDetectionMethod")
        disableMouseAccel = UserDefaults.standard.bool(forKey: "DisableMouseAccel")
        launchAtLogin = UserDefaults.standard.bool(forKey: "LaunchAtLogin")
        excludedApps = UserDefaults.standard.stringArray(forKey: "ExcludedApps") ?? []
        checkForUpdates = UserDefaults.standard.bool(forKey: "CheckForUpdates")
        // Restore the saved system acceleration so it survives a crash or
        // force quit that happened while acceleration was disabled (-1).
        let savedAccel = UserDefaults.standard.integer(forKey: "OriginalAccel")
        if savedAccel > 0 {
            origAccel = Int32(savedAccel)
        }
    }
}
