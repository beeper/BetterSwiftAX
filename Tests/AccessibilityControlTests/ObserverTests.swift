import ApplicationServices
import Foundation
import Testing
@testable import AccessibilityControl

@Suite("Observer")
struct ObserverTests {
    @Test func initInvalidPIDReportsCallerLocation() {
        let expectedLine = UInt(#line) + 2
        expectCallerLocation(expectedLine: expectedLine) {
            _ = try Accessibility.Observer(pid: -1)
        }
    }

    @Test func defaultModeAddsRunLoopSourceToCommonModesAndRemovesOnDeinit() throws {
        let pid = getpid()
        let cfLoop = RunLoop.current.getCFRunLoop()
        var source: CFRunLoopSource?

        do {
            let observer = try Accessibility.Observer(pid: pid, on: .current)
            let src = AXObserverGetRunLoopSource(observer.raw)
            source = src
            #expect(observer.runLoopMode == .commonModes)
            #expect(CFRunLoopContainsSource(cfLoop, src, .commonModes))
        }

        if let source {
            #expect(!CFRunLoopContainsSource(cfLoop, source, .commonModes))
        }
    }

    @Test func failedObserveReleasesCallbackAndReportsCallerLocation() throws {
        final class Sentinel {}

        let pid = getpid()
        let element = Accessibility.Element(pid: pid)
        let observer = try Accessibility.Observer(pid: pid, on: .current)

        weak var weakSentinel: Sentinel?
        do {
            let sentinel = Sentinel()
            weakSentinel = sentinel
            let expectedLine = UInt(#line) + 3
            do {
                // Non-GUI test process does not implement AX notifications, exercising the error cleanup path.
                _ = try observer.observe(.focusedWindowChanged, for: element) { _ in
                    _ = sentinel
                }
            } catch let error as AccessibilityError {
                #expect("\(error.file)" == "\(#fileID)")
                #expect(error.line == expectedLine)
            }
        }

        #expect(weakSentinel == nil)
    }

    @Test func subscriptionCancelIsIdempotentReentrantAndReleasesCallback() throws {
        final class Sentinel {}

        let pid = getpid()
        let element = Accessibility.Element(pid: pid)
        let observer = try Accessibility.Observer(pid: pid, on: .current)

        weak var weakSentinel: Sentinel?
        var invocationCount = 0

        do {
            let sentinel = Sentinel()
            weakSentinel = sentinel
            var token: Accessibility.Observer.Token?
            let subscription = ObserverSubscription(
                observer: observer,
                element: element,
                notification: kAXFocusedWindowChangedNotification as CFString
            ) { _ in
                _ = sentinel
                invocationCount += 1
                // Re-entrant cancellation inside callback must not deadlock.
                token?.cancel()
            }
            token = subscription.activate { _ in }

            subscription.invoke(with: [:])
            // Subsequent invoke after cancel must be ignored.
            subscription.invoke(with: [:])
            // Repeated cancel must be a safe no-op.
            token?.cancel()
            token = nil
        }

        #expect(invocationCount == 1)
        #expect(weakSentinel == nil)
    }

    @Test func subscriptionConcurrentCrossThreadCancelIsSafeAndReleasesResources() async throws {
        final class Sentinel {}
        final class ThreadState: @unchecked Sendable {
            private let lock = NSLock()
            private var _keepRunning = true
            var keepRunning: Bool {
                get { lock.lock(); defer { lock.unlock() }; return _keepRunning }
                set { lock.lock(); defer { lock.unlock() }; _keepRunning = newValue }
            }
        }
        final class RunLoopBox: @unchecked Sendable {
            let runLoop: RunLoop
            init(_ runLoop: RunLoop) { self.runLoop = runLoop }
        }
        final class TokenBox: @unchecked Sendable {
            let token: Accessibility.Observer.Token
            init(_ token: Accessibility.Observer.Token) { self.token = token }
        }

        let pid = getpid()
        let element = Accessibility.Element(pid: pid)
        let state = ThreadState()

        let loopBox: RunLoopBox = await withCheckedContinuation { continuation in
            let thread = Thread {
                let box = RunLoopBox(RunLoop.current)
                continuation.resume(returning: box)
                while state.keepRunning {
                    RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
                }
            }
            thread.start()
        }

        defer {
            state.keepRunning = false
        }

        weak var weakSentinel: Sentinel?
        weak var weakSubscription: ObserverSubscription?

        do {
            let observer = try Accessibility.Observer(pid: pid, on: loopBox.runLoop)
            let sentinel = Sentinel()
            weakSentinel = sentinel
            let subscription = ObserverSubscription(
                observer: observer,
                element: element,
                notification: kAXFocusedWindowChangedNotification as CFString
            ) { _ in
                _ = sentinel
            }
            weakSubscription = subscription
            let tokenBox = TokenBox(subscription.activate { _ in })

            // Cancel concurrently from multiple threads off the observer's run loop.
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<8 {
                    group.addTask {
                        tokenBox.token.cancel()
                    }
                }
            }
        }

        // Wait for the target run loop to execute the queued removal+release block.
        let deadline = Date().addingTimeInterval(1.0)
        while (weakSentinel != nil || weakSubscription != nil) && Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(weakSentinel == nil)
        #expect(weakSubscription == nil)
    }
}
