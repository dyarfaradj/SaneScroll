//
//  UpdateChecker.swift
//  SaneScroll
//

import Cocoa

final class UpdateChecker {

    static let shared = UpdateChecker()

    private let latestReleaseAPI = URL(string: "https://api.github.com/repos/dyarfaradj/SaneScroll/releases/latest")!
    private let latestReleasePage = URL(string: "https://github.com/dyarfaradj/SaneScroll/releases/latest")!

    // Silent unless a new version is found; runs at most once a day.
    func checkAutomatically() {
        guard Options.shared.checkForUpdates else { return }
        let lastCheck = UserDefaults.standard.double(forKey: "LastUpdateCheck")
        let now = Date().timeIntervalSince1970
        guard now - lastCheck > 86_400 else { return }
        UserDefaults.standard.set(now, forKey: "LastUpdateCheck")
        check(userInitiated: false)
    }

    func check(userInitiated: Bool) {
        var request = URLRequest(url: latestReleaseAPI)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            let latest = data.flatMap(Self.parseTag)
            DispatchQueue.main.async {
                self?.handleResult(latestVersion: latest, userInitiated: userInitiated)
            }
        }.resume()
    }

    private static func parseTag(_ data: Data) -> String? {
        let json = try? JSONSerialization.jsonObject(with: data)
        return (json as? [String: Any])?["tag_name"] as? String
    }

    private func handleResult(latestVersion: String?, userInitiated: Bool) {
        guard let latestVersion = latestVersion else {
            if userInitiated {
                showAlert(
                    title: NSLocalizedString("UpdateCheckFailedTitle", comment: ""),
                    message: NSLocalizedString("UpdateCheckFailedMessage", comment: "")
                )
            }
            return
        }

        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        if Self.isVersion(latestVersion, newerThan: currentVersion) {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("UpdateAvailableTitle", comment: "")
            alert.informativeText = String(
                format: NSLocalizedString("UpdateAvailableMessage", comment: ""),
                latestVersion, currentVersion)
            alert.addButton(withTitle: NSLocalizedString("UpdateDownload", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("UpdateLater", comment: ""))
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(latestReleasePage)
            }
        } else if userInitiated {
            showAlert(
                title: NSLocalizedString("UpToDateTitle", comment: ""),
                message: String(format: NSLocalizedString("UpToDateMessage", comment: ""), currentVersion)
            )
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    // Numeric comparison of dot-separated components; tolerates a leading "v".
    static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        func components(_ version: String) -> [Int] {
            version
                .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                .split(separator: ".")
                .map { Int($0) ?? 0 }
        }
        let a = components(candidate)
        let b = components(current)
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
