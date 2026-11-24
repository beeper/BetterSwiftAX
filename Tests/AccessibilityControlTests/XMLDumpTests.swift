import ApplicationServices
import Foundation
import Testing
@testable import AccessibilityControl

@Suite("XMLDumper")
struct XMLDumpTests {
    @Test func escapesSpecialCharactersAndWhitespace() {
        let input = "a&b \"c\" <d> \r\n\t"
        #expect(input.xmlEscaped == "a&amp;b &quot;c&quot; &lt;d&gt; &#13;&#10;&#9;")
    }

    @Test func sanitizesDoubleHyphensInComments() {
        for raw in ["--", "---", "----", "foo--bar---baz"] {
            let comment = raw.asComment
            #expect(comment.hasPrefix("<!-- "))
            #expect(comment.hasSuffix(" -->"))
            let inner = String(comment.dropFirst(5).dropLast(4))
            #expect(!inner.contains("--"))
        }
    }

    @Test func partitionAttributesKeepsNonElementAndHeterogeneousArrays() {
        let el1 = Accessibility.Element.systemWide
        let el2 = Accessibility.Element(pid: getpid())

        let input: [String: Any] = [
            "AXStrings": ["one", "two"],
            "AXEmpty": [Any](),
            "AXMixed": [el1.raw, "not-an-element"] as [Any],
            "AXElementArray": [el1.raw, el2.raw] as [Any],
            "AXSingleElement": el1.raw,
            "AXTitle": "Hello",
        ]

        let (scalar, elements) = XMLDumper.partitionAttributes(input)

        #expect(scalar.map(\.name) == ["AXEmpty", "AXMixed", "AXStrings", "AXTitle"])
        #expect(elements.keys.sorted() == ["AXElementArray", "AXSingleElement"])
        #expect(elements["AXElementArray"]?.count == 2)
        #expect(elements["AXSingleElement"]?.count == 1)
    }

    @Test func formatAttributeUsesStructDescriptionAndEscapes() throws {
        let rawPoint = try #require(CGPoint(x: 10, y: 20).axRaw())
        let formattedPoint = XMLDumper.formatAttribute(name: "AXPosition", value: rawPoint)
        #expect(formattedPoint.hasPrefix("AXPosition=\""))
        #expect(formattedPoint.contains("point"))

        let formattedText = XMLDumper.formatAttribute(name: "AXValue", value: "line1\n\"line2\"")
        #expect(formattedText == "AXValue=\"line1&#10;&quot;line2&quot;\"")
    }

    @Test func dumpRespectsMaxDepthZero() throws {
        var output = ""
        try Accessibility.Element.systemWide.dumpXML(to: &output, maxDepth: 0)
        #expect(output.contains("reached max depth (0 >= 0)"))
    }
}
