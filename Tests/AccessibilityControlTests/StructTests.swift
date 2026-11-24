import ApplicationServices
import Foundation
import Testing
@testable import AccessibilityControl

@Suite("Accessibility.Struct")
struct StructTests {
    private func roundTrip(_ value: Accessibility.Struct) throws -> Accessibility.Struct {
        let raw = try #require(value.raw())
        return try #require(Accessibility.Struct(erased: raw))
    }

    @Test func pointRoundTrips() throws {
        let point = CGPoint(x: 12.5, y: -3)
        guard case let .point(result) = try roundTrip(.point(point)) else {
            Issue.record("expected .point"); return
        }
        #expect(result == point)
    }

    @Test func sizeRoundTrips() throws {
        let size = CGSize(width: 640, height: 480)
        guard case let .size(result) = try roundTrip(.size(size)) else {
            Issue.record("expected .size"); return
        }
        #expect(result == size)
    }

    @Test func rectRoundTrips() throws {
        let rect = CGRect(x: 10, y: 20, width: 300, height: 400)
        guard case let .rect(result) = try roundTrip(.rect(rect)) else {
            Issue.record("expected .rect"); return
        }
        #expect(result == rect)
    }

    @Test(arguments: [0..<0, 0..<5, 7..<42])
    func rangeRoundTrips(range: Range<Int>) throws {
        guard case let .range(result) = try roundTrip(.range(range)) else {
            Issue.record("expected .range"); return
        }
        #expect(result == range)
    }

    @Test func errorRoundTrips() throws {
        guard case let .error(result) = try roundTrip(.error(AccessibilityError(.noValue))) else {
            Issue.record("expected .error"); return
        }
        #expect(result.code == .noValue)
    }

    @Test func nonAXValueIsRejected() {
        #expect(Accessibility.Struct(erased: "not a value" as CFString) == nil)
        #expect(Accessibility.Struct(erased: 42 as CFNumber) == nil)
    }

    @Test func negativeLengthCFRangeReturnsNilInsteadOfCrashing() throws {
        var negative = CFRange(location: 5, length: -1)
        let rawNegative = try #require(AXValueCreate(.cfRange, &negative))
        #expect(Accessibility.Struct(erased: rawNegative) == nil)
        #expect(Range<Int>(axRaw: rawNegative) == nil)

        var notFound = CFRange(location: kCFNotFound, length: -1)
        let rawNotFound = try #require(AXValueCreate(.cfRange, &notFound))
        #expect(Accessibility.Struct(erased: rawNotFound) == nil)
    }

    @Test func overflowingCFRangeReturnsNilInsteadOfCrashing() throws {
        var overflowing = CFRange(location: Int.max, length: 1)
        let raw = try #require(AXValueCreate(.cfRange, &overflowing))
        #expect(Accessibility.Struct(erased: raw) == nil)
        #expect(Range<Int>(axRaw: raw) == nil)
    }
}

@Suite("Geometry conformances")
struct GeometryConvertibleTests {
    @Test func mismatchedKindsReturnNil() throws {
        let sizeRaw = try #require(CGSize(width: 1, height: 1).axRaw())
        #expect(CGPoint(axRaw: sizeRaw) == nil)
        #expect(CGRect(axRaw: sizeRaw) == nil)
        #expect(Range<Int>(axRaw: sizeRaw) == nil)
        #expect(AccessibilityError(axRaw: sizeRaw) == nil)
    }
}
