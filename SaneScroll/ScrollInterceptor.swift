//
//  ScrollInterceptor.swift
//  SaneScroll
//
//  Created by Theron Tjapkes on 7/25/20.
//  Copyright © 2020 Theron Tjapkes. All rights reserved.
//

import Foundation
import CoreGraphics

class ScrollInterceptor {

    static let shared = ScrollInterceptor()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapRunLoop: CFRunLoop?

    // Where the magic happens
    let scrollEventCallback: CGEventTapCallBack = { (proxy, type, event, refcon) in
        // If the tap is disabled by the system, re-enable it
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let refcon = refcon {
                let tap = Unmanaged<AnyObject>.fromOpaque(refcon).takeUnretainedValue()
                if let machPort = tap as! CFMachPort? {
                    CGEvent.tapEnable(tap: machPort, enable: true)
                }
            }
            return Unmanaged.passUnretained(event)
        }

        var isWheel: Bool = true
        if !Options.shared.alternateDetectionMethod {
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
            if Options.shared.invertVerticalScroll {
                event.setIntegerValueField(
                    .scrollWheelEventDeltaAxis1, value: -event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
            }
            if Options.shared.invertHorizontalScroll {
                event.setIntegerValueField(
                    .scrollWheelEventDeltaAxis2, value: -event.getIntegerValueField(.scrollWheelEventDeltaAxis2))
            }
            if Options.shared.disableScrollAccel {
                event.setIntegerValueField(.scrollWheelEventDeltaAxis1,
                    value: event.getIntegerValueField(.scrollWheelEventDeltaAxis1).signum() * Options.shared.scrollLines)
            }
        }
        return Unmanaged.passUnretained(event)
    }

    // Intercept scroll wheel events
    func interceptScroll() {
        // Don't create multiple taps
        guard eventTap == nil else { return }

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }

            let tap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .tailAppendEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(1 << CGEventType.scrollWheel.rawValue),
                callback: self.scrollEventCallback,
                userInfo: nil
            )

            guard let tap = tap else { return }

            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            let currentRunLoop = CFRunLoopGetCurrent()

            CFRunLoopAddSource(currentRunLoop, source, CFRunLoopMode.commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)

            self.eventTap = tap
            self.runLoopSource = source
            self.tapRunLoop = currentRunLoop

            CFRunLoopRun()
        }
    }

    // Clean up event tap and stop the run loop
    func stopIntercepting() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoop = tapRunLoop {
            if let source = runLoopSource {
                CFRunLoopRemoveSource(runLoop, source, CFRunLoopMode.commonModes)
            }
            CFRunLoopStop(runLoop)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        eventTap = nil
        runLoopSource = nil
        tapRunLoop = nil
    }
}
