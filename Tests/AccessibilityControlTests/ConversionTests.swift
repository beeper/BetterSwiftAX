import ApplicationServices
import Foundation
import Testing
@testable import AccessibilityControl

@Suite("AX value conversion")
struct ConversionTests {
    @Test func arrayOfConvertiblesRoundTrips() throws {
        let points = [CGPoint(x: 1, y: 1), CGPoint(x: 2, y: 3)]
        let raw = try #require(points.axRaw())
        #expect([CGPoint](axRaw: raw) == points)
    }

    @Test func arrayFailsIfAnyElementFailsToConvert() throws {
        let mixed: [AnyObject] = [
            try #require(CGPoint(x: 1, y: 1).axRaw()),
            try #require(CGSize(width: 1, height: 1).axRaw()),
        ]
        #expect([CGPoint](axRaw: mixed as AnyObject) == nil)
    }

    @Test func dictionaryOfConvertiblesRoundTrips() throws {
        let sizes = ["small": CGSize(width: 1, height: 2), "large": CGSize(width: 100, height: 200)]
        let raw = try #require(sizes.axRaw())
        #expect([String: CGSize](axRaw: raw) == sizes)
    }

    @Test func dictionaryFailsIfAnyValueFailsToConvert() throws {
        let mixed: [String: AnyObject] = [
            "ok": try #require(CGSize(width: 1, height: 1).axRaw()),
            "bad": "string" as NSString,
        ]
        #expect([String: CGSize](axRaw: mixed as AnyObject) == nil)
    }

    @Test func convertFromAXUsesConvertibleConformance() throws {
        let raw = try #require(CGRect(x: 1, y: 2, width: 3, height: 4).axRaw())
        let rect: CGRect? = Accessibility.convertFromAX(raw)
        #expect(rect == CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    @Test func convertFromAXReturnsNilForWrongType() {
        let number: Int? = Accessibility.convertFromAX("not a number" as NSString)
        #expect(number == nil)

        let point: CGPoint? = Accessibility.convertFromAX("not a point" as NSString)
        #expect(point == nil)
    }
}
