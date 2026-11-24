import AppKit
import Foundation
import Testing
@testable import WindowControl

@Suite("Cocoa/screen rect flip")
@MainActor
struct RectFlipTests {
    @Test func flipIsItsOwnInverse() {
        let rect = NSRect(x: 100, y: 200, width: 300, height: 150)
        #expect(rect.flippedBetweenCocoaAndScreenSpace().flippedBetweenCocoaAndScreenSpace() == rect)
    }

    @Test(.enabled(if: !NSScreen.screens.isEmpty, "needs a display"))
    func flipMeasuresFromPrimaryDisplayHeight() throws {
        let primaryHeight = try #require(NSScreen.screens.first).frame.height
        let rect = NSRect(x: 0, y: 0, width: 10, height: 10)
        #expect(rect.flippedBetweenCocoaAndScreenSpace().minY == primaryHeight - 10)
    }
}

@Suite("Window.describe")
struct WindowDescribeTests {
    @Test func unknownWindowIDThrowsWindowNotFound() {
        #expect(throws: Window.Error.self) {
            _ = try Window(raw: 0).describe()
        }
    }

    @Test func describesExistingWindowDirectly() throws {
        let windows = try Window.list(.onScreen)
        guard let first = windows.first else { return }
        let desc = try first.describe()
        #expect(desc.window == first)
    }
}

@Suite("Process.monitorExit")
struct ProcessMonitorTests {
    @Test func rejectsNonPositivePID() {
        #expect(throws: Process.Error.self) {
            _ = try Process.monitorExit(pid: 0) {}
        }
        #expect(throws: Process.Error.self) {
            _ = try Process.monitorExit(pid: -1) {}
        }
    }

    @Test func firesOnceWhenMonitoredChildExits() throws {
        let proc = Foundation.Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/sleep")
        proc.arguments = ["0.05"]
        try proc.run()

        let exited = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var callCount = 0

        let monitor = try Process.monitorExit(pid: proc.processIdentifier) {
            lock.lock()
            callCount += 1
            lock.unlock()
            exited.signal()
        }
        defer { monitor.cancel() }

        let result = exited.wait(timeout: .now() + 2.0)
        #expect(result == .success)
        #expect(callCount == 1)
    }

    @Test func droppingMonitorCancelsAndReleasesCallback() throws {
        final class Sentinel {}

        let proc = Foundation.Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/sleep")
        proc.arguments = ["2"]
        try proc.run()
        defer { proc.terminate() }

        weak var weakSentinel: Sentinel?
        do {
            let sentinel = Sentinel()
            weakSentinel = sentinel
            let monitor = try Process.monitorExit(pid: proc.processIdentifier) {
                _ = sentinel
            }
            monitor.cancel()
        }

        #expect(weakSentinel == nil)
    }
}

@Suite("Dock.Observer")
struct DockObserverTests {
    private final class FakeMonitor: Dock.Observer.MonitorHandle {
        let pid: pid_t
        private let lock = NSLock()
        private var handler: (() -> Void)?
        private(set) var cancelled = false

        init(pid: pid_t, handler: @escaping () -> Void) {
            self.pid = pid
            self.handler = handler
        }

        func cancel() {
            lock.lock()
            cancelled = true
            handler = nil
            lock.unlock()
        }

        func triggerExit() {
            lock.lock()
            let cb = handler
            handler = nil
            lock.unlock()
            cb?()
        }
    }

    @Test func initDoesNotBlockWhenDockIsUnavailable() {
        let start = Date()
        let observer = Dock.Observer(
            onExit: {},
            pidProvider: { nil },
            monitorFactory: { pid, handler in FakeMonitor(pid: pid, handler: handler) },
            retryTimeout: 5,
            retryInterval: 0.1
        )
        let elapsed = Date().timeIntervalSince(start)
        observer.cancel()

        #expect(elapsed < 0.2)
    }

    @Test func droppingObserverDeallocatesAndCancelsMonitor() {
        let monitorBox = NSLock()
        var createdMonitor: FakeMonitor?
        weak var weakObserver: Dock.Observer?

        do {
            let observer = Dock.Observer(
                onExit: {},
                pidProvider: { 1234 },
                monitorFactory: { pid, handler in
                    let m = FakeMonitor(pid: pid, handler: handler)
                    monitorBox.lock()
                    createdMonitor = m
                    monitorBox.unlock()
                    return m
                },
                retryTimeout: 1,
                retryInterval: 0.01
            )
            weakObserver = observer
            #expect(createdMonitor?.pid == 1234)
            #expect(createdMonitor?.cancelled == false)
        }

        #expect(weakObserver == nil)
        #expect(createdMonitor?.cancelled == true)
    }

    @Test func waitsForNewPIDAfterExitAndReattaches() throws {
        let stateLock = NSLock()
        var currentPID: pid_t? = 100
        var monitors: [FakeMonitor] = []

        let exitNotified = DispatchSemaphore(value: 0)
        var exitCount = 0

        let observer = Dock.Observer(
            onExit: {
                stateLock.lock()
                exitCount += 1
                stateLock.unlock()
                exitNotified.signal()
            },
            pidProvider: {
                stateLock.lock()
                defer { stateLock.unlock() }
                return currentPID
            },
            monitorFactory: { pid, handler in
                let m = FakeMonitor(pid: pid, handler: handler)
                stateLock.lock()
                monitors.append(m)
                stateLock.unlock()
                return m
            },
            retryTimeout: 2,
            retryInterval: 0.01
        )
        defer { observer.cancel() }

        #expect(monitors.count == 1)
        #expect(monitors[0].pid == 100)

        // Simulate Dock terminating, briefly still returning the old PID, then relaunching with PID 200.
        monitors[0].triggerExit()
        Thread.sleep(forTimeInterval: 0.03)
        stateLock.lock()
        #expect(exitCount == 0)
        currentPID = 200
        stateLock.unlock()

        let result = exitNotified.wait(timeout: .now() + 2.0)
        #expect(result == .success)

        stateLock.lock()
        #expect(exitCount == 1)
        #expect(monitors.count == 2)
        #expect(monitors[1].pid == 200)
        stateLock.unlock()
    }
}
