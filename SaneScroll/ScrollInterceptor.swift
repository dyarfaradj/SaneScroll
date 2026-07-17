//
//  ScrollInterceptor.swift
//  SaneScroll
//
//  Created by Theron Tjapkes on 7/25/20.
//  Copyright © 2020 Theron Tjapkes. All rights reserved.
//

import Foundation
import CoreGraphics

final class ScrollInterceptor {

    static let shared = ScrollInterceptor()

    // Copy of the options the tap callback needs, so the callback thread
    // never reads state the main thread may be mutating.
    private struct OptionsSnapshot {
        var invertVerticalScroll = true
        var invertHorizontalScroll = false
        var disableScrollAccel = true
        var scrollLines: Int64 = 3
        var alternateDetectionMethod = false
        var excludedBundleIDs: Set<String> = []
    }

    private let lock = NSLock()
    private var snapshot = OptionsSnapshot()
    private var paused = false
    private var frontmostBundleID: String?
    private var started = false
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapRunLoop: CFRunLoop?

    // Call whenever options change; safe to call from any thread.
    func refreshOptions() {
        let options = Options.shared
        let newSnapshot = OptionsSnapshot(
            invertVerticalScroll: options.invertVerticalScroll,
            invertHorizontalScroll: options.invertHorizontalScroll,
            disableScrollAccel: options.disableScrollAccel,
            scrollLines: options.scrollLines,
            alternateDetectionMethod: options.alternateDetectionMethod,
            excludedBundleIDs: Set(options.excludedApps)
        )
        lock.lock()
        snapshot = newSnapshot
        lock.unlock()
    }

    private func currentSnapshot() -> OptionsSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return snapshot
    }

    // Temporarily pass events through unmodified without tearing down the
    // tap. Session-only; not persisted.
    var isPaused: Bool {
        lock.lock()
        defer { lock.unlock() }
        return paused
    }

    func setPaused(_ newValue: Bool) {
        lock.lock()
        paused = newValue
        lock.unlock()
    }

    // Updated from the main thread as apps activate; read by the callback
    // to skip apps the user excluded.
    func setFrontmostApp(bundleID: String?) {
        lock.lock()
        frontmostBundleID = bundleID
        lock.unlock()
    }

    // True when events should pass through untouched (paused, or the
    // active app is excluded).
    fileprivate func shouldPassThrough() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if paused { return true }
        if let bundleID = frontmostBundleID, snapshot.excludedBundleIDs.contains(bundleID) {
            return true
        }
        return false
    }

    // The system disables taps that are slow to respond (common after
    // sleep/wake or under heavy load); re-enable ours so scrolling keeps
    // being modified without needing an app restart.
    fileprivate func reenableTap() {
        lock.lock()
        let tap = eventTap
        lock.unlock()
        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    // Where the magic happens
    private static let scrollEventCallback: CGEventTapCallBack = { (_, type, event, _) in
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            ScrollInterceptor.shared.reenableTap()
            return Unmanaged.passUnretained(event)
        }

        if ScrollInterceptor.shared.shouldPassThrough() {
            return Unmanaged.passUnretained(event)
        }

        let options = ScrollInterceptor.shared.currentSnapshot()

        var isWheel: Bool = true
        if !options.alternateDetectionMethod {
            // scrollWheelEventIsContinuous will be 0 for mice and 1 for trackpads
            if event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0 {
                isWheel = false
            }
        } else {
            // Undocumented values but seem to be non-zero only for trackpads
            if event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0 ||
                event.getDoubleValueField(.scrollWheelEventScrollCount) != 0.0 ||
                event.getDoubleValueField(.scrollWheelEventScrollPhase) != 0.0 {
                isWheel = false
            }
        }

        if isWheel {
            if options.invertVerticalScroll {
                event.setIntegerValueField(
                    .scrollWheelEventDeltaAxis1, value: -event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
            }
            if options.invertHorizontalScroll {
                event.setIntegerValueField(
                    .scrollWheelEventDeltaAxis2, value: -event.getIntegerValueField(.scrollWheelEventDeltaAxis2))
            }
            if options.disableScrollAccel {
                event.setIntegerValueField(.scrollWheelEventDeltaAxis1,
                    value: event.getIntegerValueField(.scrollWheelEventDeltaAxis1).signum() * options.scrollLines)
            }
        }
        return Unmanaged.passUnretained(event)
    }

    // Intercept scroll wheel events
    func interceptScroll() {
        // Don't create multiple taps
        lock.lock()
        if started {
            lock.unlock()
            return
        }
        started = true
        lock.unlock()

        refreshOptions()

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }

            let tap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .tailAppendEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(1 << CGEventType.scrollWheel.rawValue),
                callback: ScrollInterceptor.scrollEventCallback,
                userInfo: nil
            )

            guard let tap = tap else {
                self.lock.lock()
                self.started = false
                self.lock.unlock()
                return
            }

            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            let currentRunLoop = CFRunLoopGetCurrent()

            CFRunLoopAddSource(currentRunLoop, source, CFRunLoopMode.commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)

            self.lock.lock()
            self.eventTap = tap
            self.runLoopSource = source
            self.tapRunLoop = currentRunLoop
            self.lock.unlock()

            CFRunLoopRun()
        }
    }

    // Clean up event tap and stop the run loop
    func stopIntercepting() {
        lock.lock()
        let tap = eventTap
        let source = runLoopSource
        let runLoop = tapRunLoop
        eventTap = nil
        runLoopSource = nil
        tapRunLoop = nil
        started = false
        lock.unlock()

        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoop = runLoop {
            if let source = source {
                CFRunLoopRemoveSource(runLoop, source, CFRunLoopMode.commonModes)
            }
            CFRunLoopStop(runLoop)
        }
        if let tap = tap {
            CFMachPortInvalidate(tap)
        }
    }
}
