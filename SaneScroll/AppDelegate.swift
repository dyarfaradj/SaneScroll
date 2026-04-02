//
//  AppDelegate.swift
//  SaneScroll
//
//  Created by Theron Tjapkes on 7/24/20.
//  Copyright © 2020 Theron Tjapkes. All rights reserved.
//

import Cocoa
import Foundation
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    var prefsWindow: NSWindow?
    var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification){
        refresh()
        let trusted = AXIsProcessTrusted()
        if trusted {
            ScrollInterceptor.shared.interceptScroll()
        } else {
            accessibilityAlert()
            pollAccessibility()
        }
    }
    
    func applicationWillTerminate(_ anotification: Notification) {
        ScrollInterceptor.shared.stopIntercepting()
        // Reset the mouse acceleration when application terminates
        Options.shared.disableMouseAccel = false
        disableMouseAccel()
    }
    
    private var accessibilityPollCount = 0
    private let maxAccessibilityPolls = 300 // 5 minutes at 1s intervals

    func pollAccessibility() {
        accessibilityPollCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            if AXIsProcessTrusted() {
                ScrollInterceptor.shared.interceptScroll()
            } else if self.accessibilityPollCount < self.maxAccessibilityPolls {
                self.pollAccessibility()
            }
        }
    }
    
    func accessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("PermissionsTitle", comment: "")
        alert.informativeText = NSLocalizedString("PermissionsMessage", comment: "")
        alert.addButton(withTitle: NSLocalizedString("OpenPreferences", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
            AXIsProcessTrustedWithOptions(options)
            //NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
        else {
            NSApp.terminate(self)
        }
    }
    
    func refresh() {
        Options.shared.loadOptions()
        MenuBarItem.shared.refreshVisibility()
        disableMouseAccel()
        // Rebuild menu to reflect updated toggle states
        MenuBarItem.shared.rebuildMenu()
    }
    
    @objc func preferencesClicked(_ sender: Any) {
        if AXIsProcessTrusted() {
            showPreferences()
        } else {
            accessibilityAlert()
        }
    }
    
    @objc func showAbout(_ sender: Any) {
        if aboutWindow == nil {
            let aboutView = AboutView()
            let hostingController = NSHostingController(rootView: aboutView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "About SaneScroll"
            window.styleMask = [.titled, .closable]
            window.delegate = self
            window.setContentSize(hostingController.view.fittingSize)
            window.center()
            aboutWindow = window
        }
        aboutWindow?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showPreferences() {
        if prefsWindow == nil {
            let prefsView = PreferencesView(onDismiss: { [weak self] applied in
                if applied {
                    self?.refresh()
                }
                self?.prefsWindow?.close()
            })
            let hostingController = NSHostingController(rootView: prefsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "SaneScroll"
            window.styleMask = [.titled, .closable]
            window.delegate = self
            window.setContentSize(hostingController.view.fittingSize)
            window.center()
            prefsWindow = window
        }
        prefsWindow?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) === prefsWindow {
            prefsWindow = nil
        } else if (notification.object as? NSWindow) === aboutWindow {
            aboutWindow = nil
        }
    }
    
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showPreferences()
        }
        return true
    }
    
    func disableMouseAccel() {
        // Based on https://github.com/apsun/NoMouseAccel
        let client = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
        let mouseAccelerationType: CFString = kIOHIDMouseAccelerationType as NSString

        // Get the starting acceleration value (guard against nil)
        if let originalAccelRef = IOHIDEventSystemClientCopyProperty(client, mouseAccelerationType) {
            var origAccel: Int32 = 0
            CFNumberGetValue((originalAccelRef as! CFNumber), CFNumberType.sInt32Type, &origAccel)
            // Only save it if it's not -1 (acceleration off)
            if origAccel != -1 {
                Options.shared.origAccel = origAccel
                UserDefaults.standard.set(origAccel, forKey: "OriginalAccel")
            }
        }

        if Options.shared.disableMouseAccel {
            Options.shared.accel = -1
        } else {
            Options.shared.accel = Options.shared.origAccel
        }

        // Set the mouse acceleration
        var accelValue = Options.shared.accel
        if let accelNum = CFNumberCreate(kCFAllocatorDefault, CFNumberType.sInt32Type, &accelValue) {
            IOHIDEventSystemClientSetProperty(client, mouseAccelerationType, accelNum)
        }
    }
}

