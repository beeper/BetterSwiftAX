import ApplicationServices
import Foundation

private func printAttribute(to output: inout some TextOutputStream, name: String, value: Any?) {
    guard let value else { return }
    print(" \(XMLDumper.formatAttribute(name: name, value: value))", terminator: "", to: &output)
}

public struct XMLDumper {
    public static let defaultExcludedAttributes: Set<String> = [
        // children are printed specially, so we don't need to print them out as attributes
        "AXChildren", "AXChildrenInNavigationOrder",

        // avoid redundantly printing parent elements, which can quickly bloat the result
        "AXTopLevelUIElement", "AXMenuItemPrimaryUIElement", "AXParent", "AXWindow",
    ]

    static var attributesLikelyToContainPII: Set<String> {
        [
            kAXHelpAttribute,
            kAXDescriptionAttribute,
            kAXTitleAttribute,

            // text entry area values
            kAXValueAttribute,

            kAXLabelValueAttribute,
            kAXSelectedTextAttribute,
            kAXPlaceholderValueAttribute,
            kAXFilenameAttribute,
            kAXDocumentAttribute,
        ]
    }

    public var maxDepth: Int? = nil
    public var indentation = "  "
    public var excludedRoles: Set<String> = []
    public var excludedAttributes: Set<String> = XMLDumper.defaultExcludedAttributes
    public var intendingToExcludePII = false
    public var includeActions = true
    public var includeSections = true
    public var shallow = false

    public init(
        maxDepth: Int? = nil,
        indentation: String = "  ",
        excludedRoles: Set<String> = [],
        excludedAttributes: Set<String> = XMLDumper.defaultExcludedAttributes,
        intendingToExcludePII: Bool = false,
        includeActions: Bool = true,
        includeSections: Bool = true,
        shallow: Bool = false
    ) {
        self.maxDepth = maxDepth
        self.indentation = indentation
        self.excludedRoles = excludedRoles
        self.excludedAttributes = excludedAttributes
        self.intendingToExcludePII = intendingToExcludePII
        self.includeActions = includeActions
        self.includeSections = includeSections
        self.shallow = shallow
    }

    public func dump(
        _ element: Accessibility.Element,
        to output: inout some TextOutputStream,
        depth: Int = 0,
        indent: Int = 0,
        shallow: Bool? = nil,
        preamble: String? = nil,
    ) throws {
        let shallow = shallow ?? self.shallow
        let whitespace = String(repeating: indentation, count: indent)

        if let maxDepth {
            guard depth < maxDepth else {
                print(whitespace + "⚠️ reached max depth (\(depth) >= \(maxDepth))".asComment, to: &output)
                return
            }
        }

        let role: String
        do {
            role = try element.role()
        } catch {
            print(whitespace + "⚠️ couldn't obtain role, skipping \(element): \(String(describing: error))".asComment, to: &output)
            return
        }

        guard !excludedRoles.contains(role) else {
            return
        }

        let injectedComment = if let preamble { preamble.asComment + " " } else { "" }
        print("\(whitespace)\(injectedComment)<\(role)", terminator: "", to: &output)

        // keep track of attributes that contain ui elements (as opposed to string/rect/etc.), so we can emit them as child XML elements instead of XML attributes
        var attributesPointingToElements = [String: [Accessibility.Element]]()

        if let supportedAttributes = try? element.supportedAttributes() {
            var attributes = [String: Any]()
            for attribute in supportedAttributes where !excludedAttributes.contains(attribute.name.value) {
                if let value = try? attribute() {
                    attributes[attribute.name.value] = value
                }
            }

            let partitioned = Self.partitionAttributes(attributes)
            attributesPointingToElements = partitioned.elements

            for (name, value) in partitioned.scalar {
                printAttribute(to: &output, name: name, value: value)
            }
        }

        // closing angle bracket of the opening tag
        print("> \(String(describing: element.raw).asComment)", to: &output)
        let whitespace2 = String(repeating: indentation, count: indent + 1)

        if !shallow {
            for (attributeContainingElementsName, containedElements) in attributesPointingToElements.sorted(by: { $0.key < $1.key }) {
                print(whitespace2 + "attribute containing elements".asComment + " <\(attributeContainingElementsName)>", to: &output)
                for element in containedElements {
                    try dump(element, to: &output, depth: depth + 1, indent: indent + 2, shallow: true)
                }
                print("\(whitespace2)</\(attributeContainingElementsName)>", to: &output)
            }
        }

        defer { print("\(whitespace)</\(role)>", to: &output) }

        if includeActions, let actions = try? element.supportedActions(), !actions.isEmpty {
            for (index, action) in actions.sorted(by: { $0.name.value < $1.name.value }).enumerated() {
                print(whitespace2 + "actions[\(index)]".asComment + "<action", terminator: "", to: &output)

                let actionName = action.name.value
                // some action names (maybe menu items?) are weird and look something like:
                //
                // "Name:Pin <NAME OF A CHAT>
                // Target:0x0
                // Selector:(null)"
                //
                // (yes, including the newlines.) skip these if we are intending to exclude PII
                if (intendingToExcludePII && actionName.hasPrefix("AX")) || !intendingToExcludePII {
                    printAttribute(to: &output, name: "name", value: actionName)
                }

                if !excludedAttributes.contains(kAXDescriptionAttribute) {
                    printAttribute(to: &output, name: "description", value: action.description)
                }
                print("></action>", to: &output)
            }
        }

        guard !shallow else {
            // used to avoid following cycles endlessly, since sections can point back up the tree etc.
            print(whitespace2 + "...".asComment, to: &output)
            return
        }

        if includeSections, let sections = try? element.sections() as [[String: Any]] {
            for (index, section) in sections.enumerated() {
                print(whitespace2 + "[\(index)]".asComment + " <section", terminator: "", to: &output)
                printAttribute(to: &output, name: "uniqueID", value: section["SectionUniqueID"])
                if !excludedAttributes.contains(kAXDescriptionAttribute) {
                    printAttribute(to: &output, name: "description", value: section["SectionDescription"])
                }

                if let rawObject = section["SectionObject"],
                   let sectionElement = Accessibility.Element(erased: rawObject as AnyObject) {
                    print(">", to: &output)
                    try dump(sectionElement, to: &output, depth: depth + 1, indent: indent + 2, shallow: true)
                    print("\(whitespace2)</section>", to: &output)
                } else {
                    print("></section>", to: &output)
                }
            }
        }

        guard let children = try? element.children() else { return }
        for (index, child) in children.enumerated() {
            try dump(child, to: &output, depth: depth + 1, indent: indent + 1, preamble: "children[\(index)]")
        }
    }

    internal static func formatAttribute(name: String, value: Any) -> String {
        // structs look _much nicer_ than their default description
        let text = Accessibility.Struct(erased: value as AnyObject).map { "\($0)" } ?? "\(value)"
        return "\(name)=\(text.xmlEscaped.quoted)"
    }

    internal static func partitionAttributes(
        _ attributes: [String: Any]
    ) -> (scalar: [(name: String, value: Any)], elements: [String: [Accessibility.Element]]) {
        var scalar = [(name: String, value: Any)]()
        var elements = [String: [Accessibility.Element]]()

        for (name, value) in attributes.sorted(by: { $0.key < $1.key }) {
            if let array = value as? [Any], let first = array.first {
                // check one item before converting all of them, since most arrays aren't element arrays
                guard Accessibility.Element(erased: first as AnyObject) != nil else {
                    scalar.append((name, value))
                    continue
                }
                let converted = array.compactMap { Accessibility.Element(erased: $0 as AnyObject) }
                if converted.count == array.count {
                    elements[name, default: []].append(contentsOf: converted)
                    continue
                }
            } else if let element = Accessibility.Element(erased: value as AnyObject) {
                elements[name, default: []].append(element)
                continue
            }

            scalar.append((name, value))
        }

        return (scalar, elements)
    }
}

public extension Accessibility.Element {
    func dumpXML(
        to output: inout some TextOutputStream,
        shallow: Bool = false,
        maxDepth: Int? = nil,
        excludingPII: Bool = false,
        excludingElementsWithRoles excludedRoles: Set<String> = [],
        excludingAttributes excludedAttributes: Set<String> = XMLDumper.defaultExcludedAttributes,
        includeActions: Bool = true,
        includeSections: Bool = true,
    ) throws {
        var excludedAttributes = excludedAttributes
        if excludingPII {
            excludedAttributes.formUnion(XMLDumper.attributesLikelyToContainPII)
        }

        return try XMLDumper(
            maxDepth: maxDepth,
            excludedRoles: excludedRoles,
            excludedAttributes: excludedAttributes,
            intendingToExcludePII: excludingPII,
            includeActions: includeActions,
            includeSections: includeSections,
            shallow: shallow,
        ).dump(self, to: &output)
    }
}

// MARK: -

extension String {
    var xmlEscaped: String {
        var escaped = ""
        escaped.reserveCapacity(utf8.count)
        for scalar in unicodeScalars {
            switch scalar {
            case "&": escaped += "&amp;"
            case "\"": escaped += "&quot;"
            case "<": escaped += "&lt;"
            case ">": escaped += "&gt;"
            case "\r": escaped += "&#13;"
            case "\n": escaped += "&#10;"
            case "\t": escaped += "&#9;"
            default: escaped.unicodeScalars.append(scalar)
            }
        }
        return escaped
    }

    var quoted: String {
        "\"\(self)\""
    }

    /// Splits every `--` run (illegal inside XML comments) as `- - -`.
    var xmlCommentSanitized: String {
        var sanitized = ""
        sanitized.reserveCapacity(utf8.count)
        for scalar in unicodeScalars {
            if scalar == "-", sanitized.unicodeScalars.last == "-" {
                sanitized += " "
            }
            sanitized.unicodeScalars.append(scalar)
        }
        return sanitized
    }

    var asComment: String {
        "<!-- \(xmlCommentSanitized) -->"
    }
}
