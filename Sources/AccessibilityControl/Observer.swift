import AppKit
import ApplicationServices
import Combine
import Foundation

internal final class ObserverSubscription {
    private let lock = NSLock()
    private var callback: Accessibility.Observer.Callback?
    private let observer: Accessibility.Observer
    private let element: Accessibility.Element
    private let notification: CFString

    init(
        observer: Accessibility.Observer,
        element: Accessibility.Element,
        notification: CFString,
        callback: @escaping Accessibility.Observer.Callback
    ) {
        self.observer = observer
        self.element = element
        self.notification = notification
        self.callback = callback
    }

    /// Retains `self` as the AX refcon passed to `register`, and returns the token whose
    /// cancellation balances that retain. If `register` throws, the retain is released immediately.
    func activate(
        _ register: (_ refcon: UnsafeMutableRawPointer) throws -> Void
    ) rethrows -> Accessibility.Observer.Token {
        let refcon = Unmanaged.passRetained(self)
        do {
            try register(refcon.toOpaque())
        } catch {
            refcon.release()
            throw error
        }
        return Accessibility.Observer.Token { self.cancel() }
    }

    func invoke(with info: [AnyHashable: Any]) {
        let cb = lock.withLock { callback }
        cb?(info)
    }

    private func cancel() {
        let wasActive: Bool = lock.withLock {
            defer { callback = nil }
            return callback != nil
        }
        guard wasActive else { return }

        let removeAndRelease = {
            AXObserverRemoveNotification(self.observer.raw, self.element.raw, self.notification)
            Unmanaged.passUnretained(self).release()
        }

        let cfLoop = observer.runLoop
        if let currentLoop = CFRunLoopGetCurrent(), CFEqual(currentLoop, cfLoop) {
            removeAndRelease()
        } else {
            CFRunLoopPerformBlock(cfLoop, CFRunLoopMode.commonModes.rawValue, removeAndRelease)
            CFRunLoopWakeUp(cfLoop)
        }
    }
}

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

    let subscription = Unmanaged<ObserverSubscription>
        .fromOpaque(context)
        .takeUnretainedValue()
    subscription.invoke(with: dict)
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
            private let lock = NSLock()
            private var removeAction: (() -> Void)?

            internal init(remove: @escaping () -> Void) {
                self.removeAction = remove
            }

            public func cancel() {
                let action: (() -> Void)? = lock.withLock {
                    let current = removeAction
                    removeAction = nil
                    return current
                }
                action?()
            }

            deinit {
                cancel()
            }
        }

        public typealias Callback = (_ info: [AnyHashable: Any]) -> Void

        internal let raw: AXObserver
        internal let runLoop: CFRunLoop
        internal let runLoopMode: CFRunLoopMode

        // no need to retain the entire observer so long as the individual
        // tokens are retained
        public init(
            pid: pid_t,
            on runLoop: RunLoop = .current,
            mode: RunLoop.Mode = .common,
            file: StaticString = #fileID,
            line: UInt = #line
        ) throws {
            var raw: AXObserver?
            try check(AXObserverCreateWithInfoCallback(pid, observerCallback, &raw), file: file, line: line)
            guard let raw = raw else {
                throw AccessibilityError(.failure, file: file, line: line)
            }
            self.raw = raw
            self.runLoop = runLoop.getCFRunLoop()
            self.runLoopMode = CFRunLoopMode(rawValue: mode.rawValue as CFString)

            let src = AXObserverGetRunLoopSource(raw)
            CFRunLoopAddSource(self.runLoop, src, self.runLoopMode)
        }

        deinit {
            let src = AXObserverGetRunLoopSource(raw)
            CFRunLoopRemoveSource(runLoop, src, runLoopMode)
        }

        // the token must be retained
        public func observe(
            _ notification: Notification,
            for element: Element,
            file: StaticString = #fileID,
            line: UInt = #line,
            callback: @escaping Callback
        ) throws -> Token {
            return try observe(
                NSAccessibility.Notification(from: notification),
                for: element,
                file: file,
                line: line,
                callback: callback
            )
        }

        public func observe(
            _ notification: KeyPath<Notification.Type, Notification>,
            for element: Element,
            file: StaticString = #fileID,
            line: UInt = #line,
            callback: @escaping Callback
        ) throws -> Token {
            try observe(
                Notification.self[keyPath: notification],
                for: element,
                file: file,
                line: line,
                callback: callback
            )
        }

        @_disfavoredOverload
        public func observe(
            _ notification: NSAccessibility.Notification,
            for element: Element,
            file: StaticString = #fileID,
            line: UInt = #line,
            callback: @escaping Callback
        ) throws -> Token {
            let cfNotif = notification.rawValue as CFString
            let subscription = ObserverSubscription(
                observer: self,
                element: element,
                notification: cfNotif,
                callback: callback
            )
            return try subscription.activate { refcon in
                try check(AXObserverAddNotification(raw, element.raw, cfNotif, refcon), file: file, line: line)
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
        mode: RunLoop.Mode = .common,
        file: StaticString = #fileID,
        line: UInt = #line,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> Accessibility.Observer.Token {
        try observe(
            NSAccessibility.Notification(from: notification),
            on: runLoop,
            mode: mode,
            file: file,
            line: line,
            callback: callback
        )
    }

    public func observe(
        _ notification: KeyPath<Accessibility.Notification.Type, Accessibility.Notification>,
        on runLoop: RunLoop = .current,
        mode: RunLoop.Mode = .common,
        file: StaticString = #fileID,
        line: UInt = #line,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> Accessibility.Observer.Token {
        try observe(
            Accessibility.Notification.self[keyPath: notification],
            on: runLoop,
            mode: mode,
            file: file,
            line: line,
            callback: callback
        )
    }

    // the token must be retained
    @_disfavoredOverload
    public func observe(
        _ notification: NSAccessibility.Notification,
        on runLoop: RunLoop = .current,
        mode: RunLoop.Mode = .common,
        file: StaticString = #fileID,
        line: UInt = #line,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> Accessibility.Observer.Token {
        try Accessibility.Observer(pid: pid(file: file, line: line), on: runLoop, mode: mode, file: file, line: line)
            .observe(notification, for: self, file: file, line: line, callback: callback)
    }

    public func publisher(
        for notification: Accessibility.Notification,
        on runLoop: RunLoop = .current,
        mode: RunLoop.Mode = .common,
        file: StaticString = #fileID,
        line: UInt = #line,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> AnyCancellable {
        AnyCancellable(try observe(notification, on: runLoop, mode: mode, file: file, line: line, callback: callback))
    }

    public func publisher(
        for notification: KeyPath<Accessibility.Notification.Type, Accessibility.Notification>,
        on runLoop: RunLoop = .current,
        mode: RunLoop.Mode = .common,
        file: StaticString = #fileID,
        line: UInt = #line,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> AnyCancellable {
        try publisher(
            for: Accessibility.Notification.self[keyPath: notification],
            on: runLoop,
            mode: mode,
            file: file,
            line: line,
            callback: callback
        )
    }

    @_disfavoredOverload
    public func publisher(
        for notification: NSAccessibility.Notification,
        on runLoop: RunLoop = .current,
        mode: RunLoop.Mode = .common,
        file: StaticString = #fileID,
        line: UInt = #line,
        callback: @escaping Accessibility.Observer.Callback
    ) throws -> AnyCancellable {
        AnyCancellable(try observe(notification, on: runLoop, mode: mode, file: file, line: line, callback: callback))
    }
}
