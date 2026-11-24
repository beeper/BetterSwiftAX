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

func expectCallerLocation(
    expectedLine: UInt,
    file: StaticString = #fileID,
    operation: () throws -> Void
) {
    do {
        try operation()
        Issue.record("Expected AccessibilityError to be thrown")
    } catch let error as AccessibilityError {
        #expect("\(error.file)" == "\(file)")
        #expect(error.line == expectedLine)
        #expect(!"\(error.file)".hasPrefix("/"))
    } catch {
        Issue.record("Unexpected error type: \(error)")
    }
}

@Suite("Error call-site locations")
struct ErrorLocationTests {
    @Test func windowUsesFileIDAndCallerLine() {
        let expectedLine = UInt(#line) + 2
        expectCallerLocation(expectedLine: expectedLine) {
            _ = try Accessibility.Element.systemWide.window()
        }
    }

    @Test func elementMethodsReportCallerLocation() {
        let invalid = Accessibility.Element(pid: -1)

        let timeoutLine = UInt(#line) + 2
        expectCallerLocation(expectedLine: timeoutLine) {
            try invalid.setMessagingTimeout(-5)
        }

        let actionsLine = UInt(#line) + 2
        expectCallerLocation(expectedLine: actionsLine) {
            _ = try invalid.supportedActions()
        }

        let attrsLine = UInt(#line) + 2
        expectCallerLocation(expectedLine: attrsLine) {
            _ = try invalid.supportedAttributes()
        }

        let paramAttrsLine = UInt(#line) + 2
        expectCallerLocation(expectedLine: paramAttrsLine) {
            _ = try invalid.supportedParameterizedAttributes()
        }
    }

    @Test func parameterizedAttributeReportsCallerLocation() {
        let invalid = Accessibility.Element(pid: -1)
        let attr = invalid.parameterizedAttribute(
            Accessibility.ParameterizedAttribute<Int, String>.Name("AXNonExistentParameterizedAttr")
        )

        let callLine = UInt(#line) + 2
        expectCallerLocation(expectedLine: callLine) {
            _ = try attr(0)
        }
    }
}
