import AppKit
import Foundation

public enum Dock {
    static let bundleID = "com.apple.dock"

    public static var pid: pid_t? {
        self.runningApplication()?.processIdentifier
    }

    public static func runningApplication() -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: Dock.bundleID)
            .first { !$0.isTerminated }
    }

    public final class Observer {
        internal protocol MonitorHandle: AnyObject {
            func cancel()
        }

        private let queue = DispatchQueue(label: "com.betterswiftax.dock-observer", qos: .utility)
        private let lock = NSLock()
        private let pidProvider: () -> pid_t?
        private let monitorFactory: (pid_t, @escaping () -> Void) throws -> MonitorHandle
        private let retryTimeout: TimeInterval
        private let retryInterval: TimeInterval

        private var onExit: (() -> Void)?
        private var activeMonitor: MonitorHandle?
        private var pendingRetry: DispatchWorkItem?

        public convenience init(onExit: @escaping () -> Void) {
            self.init(
                onExit: onExit,
                pidProvider: { Dock.pid },
                monitorFactory: { pid, handler in
                    try Process.monitorExit(pid: pid, handler)
                }
            )
        }

        internal init(
            onExit: @escaping () -> Void,
            pidProvider: @escaping () -> pid_t?,
            monitorFactory: @escaping (pid_t, @escaping () -> Void) throws -> MonitorHandle,
            retryTimeout: TimeInterval = 5,
            retryInterval: TimeInterval = 0.1
        ) {
            self.onExit = onExit
            self.pidProvider = pidProvider
            self.monitorFactory = monitorFactory
            self.retryTimeout = retryTimeout
            self.retryInterval = retryInterval
            attachOrScheduleRetry(
                excludingPID: nil,
                notifyOnAttach: false,
                deadline: Date().addingTimeInterval(retryTimeout)
            )
        }

        public func cancel() {
            let (monitor, retryItem) = lock.withLock {
                defer { (onExit, activeMonitor, pendingRetry) = (nil, nil, nil) }
                return (activeMonitor, pendingRetry)
            }

            retryItem?.cancel()
            monitor?.cancel()
        }

        deinit {
            cancel()
        }

        private func attachOrScheduleRetry(excludingPID: pid_t?, notifyOnAttach: Bool, deadline: Date) {
            guard !isCancelled else { return }

            if let pid = pidProvider(), pid > 0, pid != excludingPID {
                do {
                    debugLog("observing dock exit with pid=\(pid)")
                    let monitor = try monitorFactory(pid) { [weak self] in
                        self?.onDockTerminate(exitedPID: pid)
                    }

                    let attached: (oldMonitor: MonitorHandle?, callback: (() -> Void)?)? = lock.withLock {
                        guard onExit != nil else { return nil }
                        defer { (activeMonitor, pendingRetry) = (monitor, nil) }
                        return (activeMonitor, notifyOnAttach ? onExit : nil)
                    }
                    guard let attached else {
                        monitor.cancel()
                        return
                    }

                    attached.oldMonitor?.cancel()
                    attached.callback?()
                    return
                } catch {
                    debugLog("failed to observe dock pid=\(pid): \(error)")
                }
            }

            guard Date() < deadline else {
                debugLog("timed out waiting for Dock to launch")
                return
            }

            let item = DispatchWorkItem { [weak self] in
                self?.attachOrScheduleRetry(
                    excludingPID: excludingPID,
                    notifyOnAttach: notifyOnAttach,
                    deadline: deadline
                )
            }

            let scheduled: Bool = lock.withLock {
                guard onExit != nil else { return false }
                pendingRetry?.cancel()
                pendingRetry = item
                return true
            }
            guard scheduled else { return }

            queue.asyncAfter(deadline: .now() + retryInterval, execute: item)
        }

        /// `onExit` is only cleared by `cancel()`, so a nil callback means cancelled.
        private var isCancelled: Bool {
            lock.withLock { onExit == nil }
        }

        private func onDockTerminate(exitedPID: pid_t) {
            debugLog("dock terminated (pid=\(exitedPID))")
            attachOrScheduleRetry(
                excludingPID: exitedPID,
                notifyOnAttach: true,
                deadline: Date().addingTimeInterval(retryTimeout)
            )
        }
    }
}

extension Process.ExitMonitor: Dock.Observer.MonitorHandle {}
