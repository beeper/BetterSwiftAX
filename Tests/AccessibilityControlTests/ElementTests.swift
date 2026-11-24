import ApplicationServices
import Testing
@testable import AccessibilityControl

@Suite("Element(erased:)")
struct ElementTests {
    @Test func acceptsElements() throws {
        let element = try #require(Accessibility.Element(erased: Accessibility.Element.systemWide.raw))
        #expect(element == .systemWide)
    }

    @Test func rejectsNonElements() throws {
        #expect(Accessibility.Element(erased: "string" as CFString) == nil)
        #expect(Accessibility.Element(erased: try #require(CGPoint.zero.axRaw())) == nil)
    }
}
