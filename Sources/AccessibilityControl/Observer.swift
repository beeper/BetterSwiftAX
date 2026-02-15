import AppKit
import ApplicationServices
import Combine
import Foundation

private func observerCallback(
    observer _: AXObserver,
    element: AXUIElement,
    notification _: CFString,
    info: CFDictionary,
    context: UnsafeMutableRawPointer?
) {
    guard let context = context else { return }
    var dict = info as? [AnyHashable: Any] ?? [:]
    // Include the element that triggered the notification
    dict["AXUIElement"] = Accessibility.Element(raw: element)
    
    Unmanaged<Box<Accessibility.Observer.Callback>>
        .fromOpaque(context)
        .takeUnretainedValue()
        .value(dict)
}

extension Accessibility {
    public struct Notification: AccessibilityPhantomName {
        public let value: String
        
        public init(_ value: String) {
            self.value = value
        }
    }

    public final class Observer {
        public final class Token: Cancellable {
            private var removeAction: (() -> Void)?
            
            fileprivate init(remove: @escaping () -> Void) {
                self.removeAction = remove
            }
            
            public func cancel() {
                self.removeAction?()
                self.removeAction = nil
            }
            
            deinit {
                cancel()
            }
        }

        public typealias Callback = (_ info: [AnyHashable: Any]) -> Void

        private let raw: AXObserver

        // no need to retain the entire observer so long as the individual
        // tokens are retained
        public init(pid: pid_t, on runLoop: RunLoop = .current) throws {
            var raw: AXObserver?
            try check(AXObserverCreateWithInfoCallback(pid, observerCallback, &raw))
            guard let raw = raw else {
                throw AccessibilityError(.failure)
            }
            self.raw = raw

            let cfLoop = runLoop.getCFRunLoop()
            let src = AXObserverGetRunLoopSource(raw)
            // the source is auto-removed once `raw` is deinitialized
            CFRunLoopAddSource(cfLoop, src, .defaultMode)
        }

        // the token must be retained
        public func observe(
            _ notification: Notification,
            for element: Element,
            callback: @escaping Callback
        ) throws -> Token {
            return try observe(
                NSAccessibility.Notification(from: notification),
                for: element,
                callback: callback
            )
        }

        public func observe(
            _ notification: KeyPath<Notification.Type, Notification>,
            for element: Element,
            callback: @escaping Callback
        ) throws -> Token {
            try observe(Notification.self[keyPath: notification], for: element, callback: callback)
        }
        
        public func observe(
            _ notification: NSAccessibility.Notification,
            for element: Element,
            callback: @escaping Callback
        ) throws -> Token {
            let callback = Box(callback)
            let cfNotif = notification.rawValue as CFString
            try check(
                AXObserverAddNotification(
                    raw,
                    element.raw,
                    cfNotif,
                    // the callback is retained by `Token`
                    Unmanaged.passUnretained(callback).toOpaque()
                )
            )
            return Token {
                // we retain the observer here as well, to keep the run loop source around
                AXObserverRemoveNotification(self.raw, element.raw, cfNotif)
                _ = callback
            }
        }
    }
}

extension NSAccessibility.Notification {
    public init(from accessibilityNotification: Accessibility.Notification) {
        self.init(rawValue: accessibilityNotification.value)
    }
}

extension Accessibility.Element {
    // the token must be retained
    public func observe(
        _ notification: Accessibility.Notification,
        on runLoop: RunLoop = .current,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> Accessibility.Observer.Token {
        try Accessibility.Observer(pid: pid(), on: runLoop)
            .observe(notification, for: self, callback: callback)
    }

    public func observe(
        _ notification: KeyPath<Accessibility.Notification.Type, Accessibility.Notification>,
        on runLoop: RunLoop = .current,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> Accessibility.Observer.Token {
        try observe(Accessibility.Notification.self[keyPath: notification], on: runLoop, callback: callback)
    }

    // the token must be retained
    public func observe(
        _ notification: NSAccessibility.Notification,
        on runLoop: RunLoop = .current,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> Accessibility.Observer.Token {
        try Accessibility.Observer(pid: pid(), on: runLoop)
            .observe(notification, for: self, callback: callback)
    }

    public func publisher(
        for notification: Accessibility.Notification,
        on runLoop: RunLoop = .current,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> AnyCancellable {
        let token = try Accessibility.Observer(pid: pid(), on: runLoop)
            .observe(notification, for: self, callback: callback)

        return AnyCancellable(token)
    }

    public func publisher(
        for notification: KeyPath<Accessibility.Notification.Type, Accessibility.Notification>,
        on runLoop: RunLoop = .current,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> AnyCancellable {
        try publisher(
            for: Accessibility.Notification.self[keyPath: notification],
            on: runLoop,
            callback: callback
        )
    }

    public func publisher(
        for notification: NSAccessibility.Notification,
        on runLoop: RunLoop = .current,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> AnyCancellable {
        let token = try Accessibility.Observer(pid: pid(), on: runLoop)
            .observe(notification, for: self, callback: callback)
        
        return AnyCancellable(token)
    }
}
