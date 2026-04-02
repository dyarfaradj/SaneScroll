//
//  MenuBarItem.swift
//  SaneScroll
//

import Cocoa
import ServiceManagement

class MenuBarItem: NSObject {

    static let shared = MenuBarItem()
    private var statusItem: NSStatusItem?

    // MARK: - Visibility

    func refreshVisibility() {
        if Options.shared.showMenuBarIcon {
            add()
        } else {
            remove()
        }
    }

    private func add() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }
        if let button = statusItem?.button {
            if #available(macOS 11.0, *) {
                let image = NSImage(systemSymbolName: "computermouse.fill", accessibilityDescription: "SaneScroll")
                image?.isTemplate = true
                button.image = image
            } else {
                button.title = "⭥"
            }
        }
        statusItem?.menu = buildMenu()
    }

    func rebuildMenu() {
        statusItem?.menu = buildMenu()
    }

    private func remove() {
        guard let item = statusItem else { return }
        NSStatusBar.system.removeStatusItem(item)
        statusItem = nil
    }

    // MARK: - Menu Construction

    func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // ── Status header ──────────────────────────────────────
        let statusItem = NSMenuItem(title: statusSummary(), action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        if #available(macOS 11.0, *) {
            statusItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        }
        menu.addItem(statusItem)
        menu.addItem(NSMenuItem.separator())

        // ── Quick toggles ──────────────────────────────────────
        let headerItem = NSMenuItem(title: "Quick Toggles", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(toggleItem(
            title: "Invert Vertical Scroll",
            isOn: Options.shared.invertVerticalScroll,
            icon: "arrow.up.arrow.down",
            action: #selector(toggleVertical)
        ))

        menu.addItem(toggleItem(
            title: "Invert Horizontal Scroll",
            isOn: Options.shared.invertHorizontalScroll,
            icon: "arrow.left.arrow.right",
            action: #selector(toggleHorizontal)
        ))

        menu.addItem(toggleItem(
            title: "Disable Scroll Acceleration",
            isOn: Options.shared.disableScrollAccel,
            icon: "gauge.with.dots.needle.0percent",
            action: #selector(toggleScrollAccel)
        ))

        menu.addItem(toggleItem(
            title: "Disable Mouse Acceleration",
            isOn: Options.shared.disableMouseAccel,
            icon: "cursorarrow.motionlines",
            action: #selector(toggleMouseAccel)
        ))

        menu.addItem(NSMenuItem.separator())

        // ── Actions ────────────────────────────────────────────
        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.keyEquivalentModifierMask = .command
        prefsItem.target = self
        if #available(macOS 11.0, *) {
            prefsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        }
        menu.addItem(prefsItem)

        let aboutItem = NSMenuItem(title: "About SaneScroll", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        if #available(macOS 11.0, *) {
            aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        }
        menu.addItem(aboutItem)

        let sponsorItem = NSMenuItem(title: "Sponsor", action: #selector(openSponsor), keyEquivalent: "")
        sponsorItem.target = self
        if #available(macOS 11.0, *) {
            sponsorItem.image = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: nil)
        }
        menu.addItem(sponsorItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit SaneScroll", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        if #available(macOS 11.0, *) {
            quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        }
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Helpers

    private func statusSummary() -> String {
        let v = Options.shared.invertVerticalScroll ? "Inverted" : "Normal"
        let h = Options.shared.invertHorizontalScroll ? "Inverted" : "Normal"
        return "V: \(v)  ·  H: \(h)"
    }

    private func toggleItem(title: String, isOn: Bool, icon: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = isOn ? .on : .off
        if #available(macOS 11.0, *) {
            item.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        }
        return item
    }

    private func persist() {
        let opts = Options.shared
        UserDefaults.standard.set(opts.invertVerticalScroll, forKey: "InvertVerticalScroll")
        UserDefaults.standard.set(opts.invertHorizontalScroll, forKey: "InvertHorizontalScroll")
        UserDefaults.standard.set(opts.disableScrollAccel, forKey: "DisableScrollAccel")
        UserDefaults.standard.set(opts.disableMouseAccel, forKey: "DisableMouseAccel")
        statusItem?.menu = buildMenu()
    }

    // MARK: - Toggle Actions

    @objc private func toggleVertical() {
        Options.shared.invertVerticalScroll.toggle()
        persist()
    }

    @objc private func toggleHorizontal() {
        Options.shared.invertHorizontalScroll.toggle()
        persist()
    }

    @objc private func toggleScrollAccel() {
        Options.shared.disableScrollAccel.toggle()
        persist()
    }

    @objc private func toggleMouseAccel() {
        Options.shared.disableMouseAccel.toggle()
        persist()
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.disableMouseAccel()
        }
    }

    // MARK: - Menu Actions

    @objc private func openPreferences() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.preferencesClicked(self)
        }
    }

    @objc private func openAbout() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showAbout(self)
        }
    }

    @objc private func openSponsor() {
        if let url = URL(string: "https://github.com/sponsors/dyarfaradj") {
            NSWorkspace.shared.open(url)
        }
    }
}
