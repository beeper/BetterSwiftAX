import AppKit
import Foundation
import Testing
@testable import WindowControl

@Suite("retry")
struct RetryTests {
    private struct Flaky: Error {}

    @Test func retriesUntilSuccess() throws {
        var calls = 0
        var reportedAttempts: [Int] = []
        let value = try retry(withTimeout: 5, interval: 0.001, { () -> String in
            calls += 1
            if calls < 3 { throw Flaky() }
            return "done"
        }, onError: { attempt, _ in
            reportedAttempts.append(attempt)
        })
        #expect(value == "done")
        #expect(calls == 3)
        #expect(reportedAttempts == [0, 1])
    }

    @Test func rethrowsLastErrorAfterTimeout() {
        #expect(throws: Flaky.self) {
            try retry(withTimeout: 0.05, interval: 0.01) { () -> Int in throw Flaky() }
        }
    }
}

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
