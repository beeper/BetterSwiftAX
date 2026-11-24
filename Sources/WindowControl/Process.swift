import Foundation
import CWindowControl

public enum Process {
    public enum Error: Swift.Error {
        case invalidPID(pid_t)
    }

    /// A cancellable handle for a process-exit monitor. Dropping it cancels the monitor.
    public final class ExitMonitor {
        private let lock = NSLock()
        private let source: DispatchSourceProcess
        private var completion: (() -> Void)?

        fileprivate init(pid: pid_t, completion: @escaping () -> Void) {
            self.completion = completion
            source = DispatchSource.makeProcessSource(
                identifier: pid,
                eventMask: .exit,
                queue: DispatchQueue.global(qos: .utility)
            )
            source.setEventHandler { [weak self] in
                self?.handleExit()
            }
            source.resume()
        }

        private func handleExit() {
            let callback = takeCompletion()
            source.cancel()
            callback?()
        }

        public func cancel() {
            _ = takeCompletion()
            // cancelling a dispatch source more than once is a no-op
            source.cancel()
        }

        private func takeCompletion() -> (() -> Void)? {
            lock.withLock {
                defer { completion = nil }
                return completion
            }
        }

        deinit {
            cancel()
        }
    }

    /// Monitors `pid` for process exit and invokes `completion` once when it terminates.
    /// Retain the returned ``ExitMonitor``; dropping or cancelling it stops monitoring.
    public static func monitorExit(pid: pid_t, _ completion: @escaping () -> Void) throws -> ExitMonitor {
        guard pid > 0 else {
            throw Error.invalidPID(pid)
        }
        return ExitMonitor(pid: pid, completion: completion)
    }

    public static func isUnresponsive(_ pid: pid_t) throws -> Bool {
        var psn = ProcessSerialNumber()
        let err = TXTGetProcessForPID(pid, &psn)
        if err != kOSReturnSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(err))
        }

        let cid = CGSDefaultConnectionForThread()
        return CGSEventIsAppUnresponsive(cid, &psn)
    }
}
