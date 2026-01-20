import Foundation
import AccessibilityControl
import AppKit
import ArgumentParser

// MARK: - Attribute Fields

struct AttributeFields: OptionSet {
    let rawValue: Int

    static let role            = AttributeFields(rawValue: 1 << 0)
    static let roleDescription = AttributeFields(rawValue: 1 << 1)
    static let title           = AttributeFields(rawValue: 1 << 2)
    static let identifier      = AttributeFields(rawValue: 1 << 3)
    static let value           = AttributeFields(rawValue: 1 << 4)
    static let description     = AttributeFields(rawValue: 1 << 5)
    static let enabled         = AttributeFields(rawValue: 1 << 6)
    static let focused         = AttributeFields(rawValue: 1 << 7)
    static let position        = AttributeFields(rawValue: 1 << 8)
    static let size            = AttributeFields(rawValue: 1 << 9)
    static let frame           = AttributeFields(rawValue: 1 << 10)
    static let help            = AttributeFields(rawValue: 1 << 11)
    static let subrole         = AttributeFields(rawValue: 1 << 12)

    static let minimal: AttributeFields = [.role, .title, .identifier]
    static let standard: AttributeFields = [.role, .roleDescription, .title, .identifier, .value, .description]
    static let all: AttributeFields = [
        .role, .roleDescription, .title, .identifier, .value,
        .description, .enabled, .focused, .position, .size, .frame, .help, .subrole
    ]

    static func parse(_ string: String) -> AttributeFields {
        var fields: AttributeFields = []
        for name in string.lowercased().split(separator: ",") {
            switch name.trimmingCharacters(in: .whitespaces) {
            case "role": fields.insert(.role)
            case "roledescription", "role-description": fields.insert(.roleDescription)
            case "title": fields.insert(.title)
            case "identifier", "id": fields.insert(.identifier)
            case "value": fields.insert(.value)
            case "description", "desc": fields.insert(.description)
            case "enabled": fields.insert(.enabled)
            case "focused": fields.insert(.focused)
            case "position", "pos": fields.insert(.position)
            case "size": fields.insert(.size)
            case "frame": fields.insert(.frame)
            case "help": fields.insert(.help)
            case "subrole": fields.insert(.subrole)
            case "minimal": fields.formUnion(.minimal)
            case "standard": fields.formUnion(.standard)
            case "all": fields.formUnion(.all)
            default: break
            }
        }
        return fields.isEmpty ? .standard : fields
    }
}

// MARK: - Element Printer

struct ElementPrinter {
    let fields: AttributeFields
    let verbosity: Int

    func formatElement(_ element: Accessibility.Element, indent: Int = 0) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        var info: [String] = []

        if fields.contains(.role) {
            if let role: String = try? element.attribute(.init("AXRole"))() {
                info.append("role=\(role)")
            }
        }

        if fields.contains(.subrole) {
            if let subrole: String = try? element.attribute(.init("AXSubrole"))() {
                info.append("subrole=\(subrole)")
            }
        }

        if fields.contains(.roleDescription) {
            if let roleDesc: String = try? element.attribute(.init("AXRoleDescription"))() {
                info.append("roleDesc=\"\(roleDesc)\"")
            }
        }

        if fields.contains(.title) {
            if let title: String = try? element.attribute(.init("AXTitle"))() {
                let truncated = title.count > 50 ? String(title.prefix(50)) + "..." : title
                info.append("title=\"\(truncated)\"")
            }
        }

        if fields.contains(.identifier) {
            if let id: String = try? element.attribute(.init("AXIdentifier"))() {
                info.append("id=\"\(id)\"")
            }
        }

        if fields.contains(.description) {
            if let desc: String = try? element.attribute(.init("AXDescription"))() {
                let truncated = desc.count > 50 ? String(desc.prefix(50)) + "..." : desc
                info.append("desc=\"\(truncated)\"")
            }
        }

        if fields.contains(.value) {
            if let value: Any = try? element.attribute(.init("AXValue"))() {
                let strValue = String(describing: value)
                let truncated = strValue.count > 50 ? String(strValue.prefix(50)) + "..." : strValue
                info.append("value=\"\(truncated)\"")
            }
        }

        if fields.contains(.enabled) {
            if let enabled: Bool = try? element.attribute(.init("AXEnabled"))() {
                info.append("enabled=\(enabled)")
            }
        }

        if fields.contains(.focused) {
            if let focused: Bool = try? element.attribute(.init("AXFocused"))() {
                info.append("focused=\(focused)")
            }
        }

        if fields.contains(.position) {
            if let pos: CGPoint = try? element.attribute(.init("AXPosition"))() {
                info.append("pos=(\(Int(pos.x)),\(Int(pos.y)))")
            }
        }

        if fields.contains(.size) {
            if let size: CGSize = try? element.attribute(.init("AXSize"))() {
                info.append("size=(\(Int(size.width))x\(Int(size.height)))")
            }
        }

        if fields.contains(.frame) {
            if let frame: CGRect = try? element.attribute(.init("AXFrame"))() {
                info.append("frame=(\(Int(frame.origin.x)),\(Int(frame.origin.y)) \(Int(frame.width))x\(Int(frame.height)))")
            }
        }

        if fields.contains(.help) {
            if let help: String = try? element.attribute(.init("AXHelp"))() {
                let truncated = help.count > 50 ? String(help.prefix(50)) + "..." : help
                info.append("help=\"\(truncated)\"")
            }
        }

        let infoStr = info.isEmpty ? "(no attributes)" : info.joined(separator: " ")
        lines.append("\(prefix)\(infoStr)")

        if verbosity >= 2 {
            if let actions = try? element.supportedActions(), !actions.isEmpty {
                let actionNames = actions.map { $0.name.value.replacingOccurrences(of: "AX", with: "") }
                lines.append("\(prefix)  actions: \(actionNames.joined(separator: ", "))")
            }
        }

        return lines.joined(separator: "\n")
    }

    func printTree(_ element: Accessibility.Element, maxDepth: Int, currentDepth: Int = 0) {
        print(formatElement(element, indent: currentDepth))

        guard currentDepth < maxDepth else { return }

        let childrenAttr: Accessibility.Attribute<[Accessibility.Element]> = element.attribute(.init("AXChildren"))
        guard let children: [Accessibility.Element] = try? childrenAttr() else { return }

        for child in children {
            printTree(child, maxDepth: maxDepth, currentDepth: currentDepth + 1)
        }
    }
}

// MARK: - Commands

struct AXDump: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "axdump",
        abstract: "Dump accessibility tree information for running applications",
        discussion: """
            A command-line tool for exploring and debugging macOS accessibility trees.
            Requires accessibility permissions (System Preferences > Security & Privacy > Privacy > Accessibility).

            EXAMPLES:
              axdump list                     List running applications with PIDs
              axdump dump 710 -d 2            Dump Finder's tree (2 levels deep)
              axdump inspect 710 -p 0.0       Inspect first grandchild element
              axdump observe 710 -n all -v    Watch all notifications

            WORKFLOW:
              1. Use 'list' to find the PID of the target application
              2. Use 'dump' to explore the element hierarchy
              3. Use 'inspect' to read full attribute values or navigate to specific elements
              4. Use 'observe' to monitor real-time accessibility events
            """,
        subcommands: [List.self, Dump.self, Query.self, Inspect.self, Observe.self],
        defaultSubcommand: List.self
    )
}

extension AXDump {
    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "List running applications with accessibility elements",
            discussion: """
                Lists all running applications that can be inspected via accessibility APIs.
                By default, only shows regular (foreground) applications.

                EXAMPLES:
                  axdump list              List foreground apps with PIDs
                  axdump list -a           Include background/menu bar apps
                  axdump list -v           Show window count and app title
                  axdump list -av          Verbose listing of all apps
                """
        )

        @Flag(name: .shortAndLong, help: "Show all applications (including background)")
        var all: Bool = false

        @Flag(name: .shortAndLong, help: "Show detailed information")
        var verbose: Bool = false

        func run() throws {
            guard Accessibility.isTrusted(shouldPrompt: true) else {
                print("Error: Accessibility permissions required")
                print("Please grant permissions in System Preferences > Security & Privacy > Privacy > Accessibility")
                throw ExitCode.failure
            }

            let apps = NSWorkspace.shared.runningApplications
            let filteredApps = all ? apps : apps.filter { $0.activationPolicy == .regular }

            let sortedApps = filteredApps.sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }

            print("Running Applications:")
            print(String(repeating: "-", count: 60))

            for app in sortedApps {
                let name = app.localizedName ?? "Unknown"
                let pid = app.processIdentifier
                let bundleID = app.bundleIdentifier ?? "N/A"

                if verbose {
                    print("\(String(format: "%6d", pid))  \(name)")
                    print("        Bundle: \(bundleID)")

                    let element = Accessibility.Element(pid: pid)
                    let windowsAttr: Accessibility.Attribute<[Accessibility.Element]> = element.attribute(.init("AXWindows"))
                    if let windowCount = try? windowsAttr.count() {
                        print("        Windows: \(windowCount)")
                    }
                    if let title: String = try? element.attribute(.init("AXTitle"))() {
                        print("        Title: \(title)")
                    }
                    print()
                } else {
                    print("\(String(format: "%6d", pid))  \(name) (\(bundleID))")
                }
            }
        }
    }
}

extension AXDump {
    struct Dump: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Dump accessibility tree for an application",
            discussion: """
                Recursively dumps the accessibility element hierarchy starting from the
                application root or focused window. Output is indented to show nesting.

                FIELD PRESETS:
                  minimal   - role, title, identifier
                  standard  - role, roleDescription, title, identifier, value, description
                  all       - all available fields

                INDIVIDUAL FIELDS:
                  role, subrole, roleDescription (or role-description), title,
                  identifier (or id), value, description (or desc), enabled,
                  focused, position (or pos), size, frame, help

                EXAMPLES:
                  axdump dump 710                      Dump with default settings
                  axdump dump 710 -d 5                 Dump 5 levels deep
                  axdump dump 710 -f minimal           Only show role, title, id
                  axdump dump 710 -f role,title,value  Custom field selection
                  axdump dump 710 -w                   Start from focused window
                  axdump dump 710 -v 2                 Verbose (includes actions)
                """
        )

        @Argument(help: "Process ID of the application")
        var pid: Int32

        @Option(name: .shortAndLong, help: "Maximum depth to traverse (default: 3)")
        var depth: Int = 3

        @Option(name: .shortAndLong, help: "Verbosity level: 0=minimal, 1=normal, 2=detailed")
        var verbosity: Int = 1

        @Option(name: [.customShort("f"), .long], help: "Fields to display (comma-separated): role,title,identifier,value,description,enabled,focused,position,size,frame,help,subrole,roleDescription. Presets: minimal,standard,all")
        var fields: String = "standard"

        @Flag(name: .shortAndLong, help: "Start from focused window instead of application root")
        var window: Bool = false

        func run() throws {
            guard Accessibility.isTrusted(shouldPrompt: true) else {
                print("Error: Accessibility permissions required")
                throw ExitCode.failure
            }

            let appElement = Accessibility.Element(pid: pid)

            let rootElement: Accessibility.Element
            if window {
                guard let focusedWindow: Accessibility.Element = try? appElement.attribute(.init("AXFocusedWindow"))() else {
                    print("Error: Could not get focused window for PID \(pid)")
                    throw ExitCode.failure
                }
                rootElement = focusedWindow
            } else {
                rootElement = appElement
            }

            let attributeFields = AttributeFields.parse(fields)
            let printer = ElementPrinter(fields: attributeFields, verbosity: verbosity)

            if let appName: String = try? appElement.attribute(.init("AXTitle"))() {
                print("Accessibility Tree for: \(appName) (PID: \(pid))")
            } else {
                print("Accessibility Tree for PID: \(pid)")
            }
            print(String(repeating: "=", count: 60))

            printer.printTree(rootElement, maxDepth: depth)
        }
    }
}

extension AXDump {
    struct Query: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Query specific element relationships",
            discussion: """
                Query relationships between accessibility elements like parent, children,
                siblings, or list all attributes of an element.

                RELATIONS:
                  children        - Direct child elements
                  parent          - Parent element
                  siblings        - Sibling elements (same parent)
                  windows         - Application windows
                  focused         - Focused window and UI element
                  all-attributes  - All attributes with truncated values (aliases: attrs, attributes)

                EXAMPLES:
                  axdump query 710 -r windows          List all windows
                  axdump query 710 -r children         Show app's direct children
                  axdump query 710 -r children -F      Children of focused element
                  axdump query 710 -r siblings -F      Siblings of focused element
                  axdump query 710 -r all-attributes   List all attributes (truncated)
                  axdump query 710 -r focused          Show focused window and element
                """
        )

        @Argument(help: "Process ID of the application")
        var pid: Int32

        @Option(name: [.customShort("r"), .long], help: "Relationship to query: children, parent, siblings, windows, focused, all-attributes")
        var relation: String = "children"

        @Option(name: [.customShort("f"), .long], help: "Fields to display")
        var fields: String = "standard"

        @Option(name: .shortAndLong, help: "Verbosity level")
        var verbosity: Int = 1

        @Flag(name: [.customShort("F"), .long], help: "Query from focused element instead of application root")
        var focused: Bool = false

        func run() throws {
            guard Accessibility.isTrusted(shouldPrompt: true) else {
                print("Error: Accessibility permissions required")
                throw ExitCode.failure
            }

            let appElement = Accessibility.Element(pid: pid)

            let targetElement: Accessibility.Element
            if focused {
                guard let focusedElement: Accessibility.Element = try? appElement.attribute(.init("AXFocusedUIElement"))() else {
                    print("Error: Could not get focused element for PID \(pid)")
                    throw ExitCode.failure
                }
                targetElement = focusedElement
            } else {
                targetElement = appElement
            }

            let attributeFields = AttributeFields.parse(fields)
            let printer = ElementPrinter(fields: attributeFields, verbosity: verbosity)

            switch relation.lowercased() {
            case "children":
                queryChildren(of: targetElement, printer: printer)

            case "parent":
                queryParent(of: targetElement, printer: printer)

            case "siblings":
                querySiblings(of: targetElement, printer: printer)

            case "windows":
                queryWindows(of: appElement, printer: printer)

            case "focused":
                queryFocused(of: appElement, printer: printer)

            case "all-attributes", "attrs", "attributes":
                queryAllAttributes(of: targetElement)

            default:
                print("Unknown relation: \(relation)")
                print("Valid options: children, parent, siblings, windows, focused, all-attributes")
                throw ExitCode.failure
            }
        }

        private func queryChildren(of element: Accessibility.Element, printer: ElementPrinter) {
            print("Children:")
            print(String(repeating: "-", count: 40))

            let childrenAttr: Accessibility.Attribute<[Accessibility.Element]> = element.attribute(.init("AXChildren"))
            guard let children: [Accessibility.Element] = try? childrenAttr() else {
                print("(no children or unable to read)")
                return
            }

            print("Count: \(children.count)")
            print()

            for (index, child) in children.enumerated() {
                print("[\(index)] \(printer.formatElement(child))")
            }
        }

        private func queryParent(of element: Accessibility.Element, printer: ElementPrinter) {
            print("Parent:")
            print(String(repeating: "-", count: 40))

            guard let parent: Accessibility.Element = try? element.attribute(.init("AXParent"))() else {
                print("(no parent or unable to read)")
                return
            }

            print(printer.formatElement(parent))
        }

        private func querySiblings(of element: Accessibility.Element, printer: ElementPrinter) {
            print("Siblings:")
            print(String(repeating: "-", count: 40))

            guard let parent: Accessibility.Element = try? element.attribute(.init("AXParent"))() else {
                print("(no parent - cannot determine siblings)")
                return
            }

            let childrenAttr: Accessibility.Attribute<[Accessibility.Element]> = parent.attribute(.init("AXChildren"))
            guard let siblings: [Accessibility.Element] = try? childrenAttr() else {
                print("(unable to read parent's children)")
                return
            }

            let filteredSiblings = siblings.filter { $0 != element }
            print("Count: \(filteredSiblings.count)")
            print()

            for (index, sibling) in filteredSiblings.enumerated() {
                print("[\(index)] \(printer.formatElement(sibling))")
            }
        }

        private func queryWindows(of element: Accessibility.Element, printer: ElementPrinter) {
            print("Windows:")
            print(String(repeating: "-", count: 40))

            let windowsAttr: Accessibility.Attribute<[Accessibility.Element]> = element.attribute(.init("AXWindows"))
            guard let windows: [Accessibility.Element] = try? windowsAttr() else {
                print("(no windows or unable to read)")
                return
            }

            print("Count: \(windows.count)")
            print()

            for (index, window) in windows.enumerated() {
                print("[\(index)] \(printer.formatElement(window))")
            }
        }

        private func queryFocused(of element: Accessibility.Element, printer: ElementPrinter) {
            print("Focused Elements:")
            print(String(repeating: "-", count: 40))

            if let focusedWindow: Accessibility.Element = try? element.attribute(.init("AXFocusedWindow"))() {
                print("Focused Window:")
                print("  \(printer.formatElement(focusedWindow))")
                print()
            }

            if let focusedElement: Accessibility.Element = try? element.attribute(.init("AXFocusedUIElement"))() {
                print("Focused UI Element:")
                print("  \(printer.formatElement(focusedElement))")
            }
        }

        private func queryAllAttributes(of element: Accessibility.Element) {
            print("All Attributes:")
            print(String(repeating: "-", count: 40))

            guard let attributes = try? element.supportedAttributes() else {
                print("(unable to read attributes)")
                return
            }

            for attr in attributes.sorted(by: { $0.name.value < $1.name.value }) {
                let name = attr.name.value
                if let value: Any = try? attr() {
                    let strValue = String(describing: value)
                    let truncated = strValue.count > 80 ? String(strValue.prefix(80)) + "..." : strValue
                    print("\(name): \(truncated)")
                } else {
                    print("\(name): (unable to read)")
                }
            }

            print()
            print("Parameterized Attributes:")
            print(String(repeating: "-", count: 40))

            if let paramAttrs = try? element.supportedParameterizedAttributes() {
                for attr in paramAttrs.sorted(by: { $0.name.value < $1.name.value }) {
                    print(attr.name.value)
                }
            }

            print()
            print("Actions:")
            print(String(repeating: "-", count: 40))

            if let actions = try? element.supportedActions() {
                for action in actions.sorted(by: { $0.name.value < $1.name.value }) {
                    print("\(action.name.value): \(action.description)")
                }
            }
        }
    }
}

extension AXDump {
    struct Inspect: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Inspect specific attributes or elements in full detail",
            discussion: """
                Read attribute values in full (without truncation) and navigate to specific
                elements in the hierarchy using child indices.

                NAVIGATION:
                  Use -c (--child) for single-level navigation or -p (--path) for multi-level.
                  Path format: dot-separated indices, e.g., "0.3.1" means:
                    - First child of root (index 0)
                    - Fourth child of that (index 3)
                    - Second child of that (index 1)

                ATTRIBUTES:
                  Use -a to specify attributes to read. Can omit 'AX' prefix.
                  Use -a list to see all available attributes for an element.

                EXAMPLES:
                  axdump inspect 710                     Show all attributes (full values)
                  axdump inspect 710 -a list             List available attributes
                  axdump inspect 710 -a AXValue          Read AXValue in full
                  axdump inspect 710 -a Value,Title      Read multiple (AX prefix optional)
                  axdump inspect 710 -c 0                Inspect first child
                  axdump inspect 710 -p 0.2.1            Navigate to nested element
                  axdump inspect 710 -w -a AXChildren    From focused window
                  axdump inspect 710 -F -p 0             First child of focused element
                  axdump inspect 710 -j                  Output as JSON
                  axdump inspect 710 -l 500              Truncate values at 500 chars
                """
        )

        @Argument(help: "Process ID of the application")
        var pid: Int32

        @Option(name: [.customShort("p"), .long], help: "Path to element as dot-separated child indices (e.g., '0.3.1' for first child, then 4th child, then 2nd child)")
        var path: String?

        @Option(name: [.customShort("a"), .long], help: "Specific attribute(s) to read in full (comma-separated, e.g., 'AXValue,AXTitle'). Use 'list' to show available attributes.")
        var attributes: String?

        @Option(name: [.customShort("c"), .long], help: "Index of child element to inspect (shorthand for --path)")
        var child: Int?

        @Flag(name: [.customShort("F"), .long], help: "Start from focused element")
        var focused: Bool = false

        @Flag(name: .shortAndLong, help: "Start from focused window")
        var window: Bool = false

        @Option(name: [.customShort("l"), .long], help: "Maximum output length per attribute (0 for unlimited)")
        var maxLength: Int = 0

        @Flag(name: [.customShort("j"), .long], help: "Output as JSON")
        var json: Bool = false

        func run() throws {
            guard Accessibility.isTrusted(shouldPrompt: true) else {
                print("Error: Accessibility permissions required")
                throw ExitCode.failure
            }

            let appElement = Accessibility.Element(pid: pid)

            // Determine starting element
            var targetElement: Accessibility.Element = appElement

            if focused {
                guard let focusedElement: Accessibility.Element = try? appElement.attribute(.init("AXFocusedUIElement"))() else {
                    print("Error: Could not get focused element for PID \(pid)")
                    throw ExitCode.failure
                }
                targetElement = focusedElement
            } else if window {
                guard let focusedWindow: Accessibility.Element = try? appElement.attribute(.init("AXFocusedWindow"))() else {
                    print("Error: Could not get focused window for PID \(pid)")
                    throw ExitCode.failure
                }
                targetElement = focusedWindow
            }

            // Navigate to child if specified
            if let childIndex = child {
                targetElement = try navigateToChild(from: targetElement, index: childIndex)
            }

            // Navigate via path if specified
            if let pathString = path {
                targetElement = try navigateToPath(from: targetElement, path: pathString)
            }

            // Show element info
            printElementHeader(targetElement)

            // Handle attribute inspection
            if let attrString = attributes {
                if attrString.lowercased() == "list" {
                    listAttributes(of: targetElement)
                } else {
                    let attrNames = attrString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    inspectAttributes(of: targetElement, names: attrNames)
                }
            } else {
                // Default: show all attributes with full values
                inspectAllAttributes(of: targetElement)
            }
        }

        private func navigateToChild(from element: Accessibility.Element, index: Int) throws -> Accessibility.Element {
            let childrenAttr: Accessibility.Attribute<[Accessibility.Element]> = element.attribute(.init("AXChildren"))
            guard let children: [Accessibility.Element] = try? childrenAttr() else {
                throw ValidationError("Element has no children")
            }
            guard index >= 0 && index < children.count else {
                throw ValidationError("Child index \(index) out of range (0..<\(children.count))")
            }
            return children[index]
        }

        private func navigateToPath(from element: Accessibility.Element, path: String) throws -> Accessibility.Element {
            var current = element
            let indices = path.split(separator: ".").compactMap { Int($0) }

            for (step, index) in indices.enumerated() {
                let childrenAttr: Accessibility.Attribute<[Accessibility.Element]> = current.attribute(.init("AXChildren"))
                guard let children: [Accessibility.Element] = try? childrenAttr() else {
                    throw ValidationError("Element at step \(step) has no children")
                }
                guard index >= 0 && index < children.count else {
                    throw ValidationError("Child index \(index) at step \(step) out of range (0..<\(children.count))")
                }
                current = children[index]
            }

            return current
        }

        private func printElementHeader(_ element: Accessibility.Element) {
            print("Element Info:")
            print(String(repeating: "=", count: 60))

            if let role: String = try? element.attribute(.init("AXRole"))() {
                print("Role: \(role)")
            }
            if let title: String = try? element.attribute(.init("AXTitle"))() {
                print("Title: \(title)")
            }
            if let id: String = try? element.attribute(.init("AXIdentifier"))() {
                print("Identifier: \(id)")
            }

            // Show child count for navigation hints
            let childrenAttr: Accessibility.Attribute<[Accessibility.Element]> = element.attribute(.init("AXChildren"))
            if let count = try? childrenAttr.count() {
                print("Children: \(count)")
            }

            print(String(repeating: "-", count: 60))
            print()
        }

        private func listAttributes(of element: Accessibility.Element) {
            print("Available Attributes:")
            print(String(repeating: "-", count: 40))

            guard let attributes = try? element.supportedAttributes() else {
                print("(unable to read attributes)")
                return
            }

            for attr in attributes.sorted(by: { $0.name.value < $1.name.value }) {
                let name = attr.name.value
                let settable = (try? attr.isSettable()) ?? false
                let settableStr = settable ? " [settable]" : ""
                print("  \(name)\(settableStr)")
            }

            print()
            print("Parameterized Attributes:")
            print(String(repeating: "-", count: 40))

            if let paramAttrs = try? element.supportedParameterizedAttributes() {
                for attr in paramAttrs.sorted(by: { $0.name.value < $1.name.value }) {
                    print("  \(attr.name.value)")
                }
            }
        }

        private func inspectAttributes(of element: Accessibility.Element, names: [String]) {
            if json {
                var result: [String: Any] = [:]
                for name in names {
                    let attrName = name.hasPrefix("AX") ? name : "AX\(name)"
                    if let value: Any = try? element.attribute(.init(attrName))() {
                        result[attrName] = formatValueForJSON(value)
                    } else {
                        result[attrName] = NSNull()
                    }
                }
                if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
                return
            }

            for name in names {
                let attrName = name.hasPrefix("AX") ? name : "AX\(name)"
                print("\(attrName):")
                print(String(repeating: "-", count: 40))

                if let value: Any = try? element.attribute(.init(attrName))() {
                    let strValue = formatValue(value)
                    if maxLength > 0 && strValue.count > maxLength {
                        print(String(strValue.prefix(maxLength)))
                        print("... (truncated, total length: \(strValue.count))")
                    } else {
                        print(strValue)
                    }
                } else {
                    print("(unable to read or no value)")
                }
                print()
            }
        }

        private func inspectAllAttributes(of element: Accessibility.Element) {
            guard let attributes = try? element.supportedAttributes() else {
                print("(unable to read attributes)")
                return
            }

            if json {
                var result: [String: Any] = [:]
                for attr in attributes {
                    if let value: Any = try? attr() {
                        result[attr.name.value] = formatValueForJSON(value)
                    }
                }
                if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
                return
            }

            print("All Attributes (full values):")
            print(String(repeating: "-", count: 40))

            for attr in attributes.sorted(by: { $0.name.value < $1.name.value }) {
                let name = attr.name.value

                if let value: Any = try? attr() {
                    let strValue = formatValue(value)
                    if maxLength > 0 && strValue.count > maxLength {
                        print("\(name): \(String(strValue.prefix(maxLength)))... (truncated)")
                    } else if strValue.contains("\n") || strValue.count > 80 {
                        print("\(name):")
                        print(strValue.split(separator: "\n", omittingEmptySubsequences: false)
                            .map { "  \($0)" }
                            .joined(separator: "\n"))
                    } else {
                        print("\(name): \(strValue)")
                    }
                } else {
                    print("\(name): (unable to read)")
                }
            }
        }

        private func formatValue(_ value: Any) -> String {
            switch value {
            case let element as Accessibility.Element:
                var parts: [String] = ["<Element"]
                if let role: String = try? element.attribute(.init("AXRole"))() {
                    parts.append("role=\(role)")
                }
                if let title: String = try? element.attribute(.init("AXTitle"))() {
                    parts.append("title=\"\(title)\"")
                }
                if let id: String = try? element.attribute(.init("AXIdentifier"))() {
                    parts.append("id=\"\(id)\"")
                }
                parts.append(">")
                return parts.joined(separator: " ")

            case let elements as [Accessibility.Element]:
                var lines: [String] = ["[\(elements.count) elements]"]
                for (index, element) in elements.enumerated() {
                    var parts: [String] = ["  [\(index)]"]
                    if let role: String = try? element.attribute(.init("AXRole"))() {
                        parts.append("role=\(role)")
                    }
                    if let title: String = try? element.attribute(.init("AXTitle"))() {
                        parts.append("title=\"\(title)\"")
                    }
                    if let id: String = try? element.attribute(.init("AXIdentifier"))() {
                        parts.append("id=\"\(id)\"")
                    }
                    lines.append(parts.joined(separator: " "))
                }
                return lines.joined(separator: "\n")

            case let structValue as Accessibility.Struct:
                switch structValue {
                case .point(let point):
                    return "(\(point.x), \(point.y))"
                case .size(let size):
                    return "\(size.width) x \(size.height)"
                case .rect(let rect):
                    return "origin=(\(rect.origin.x), \(rect.origin.y)) size=(\(rect.width) x \(rect.height))"
                case .range(let range):
                    return "\(range.lowerBound)..<\(range.upperBound)"
                case .error(let error):
                    return "Error: \(error)"
                }

            case let point as CGPoint:
                return "(\(point.x), \(point.y))"

            case let size as CGSize:
                return "\(size.width) x \(size.height)"

            case let rect as CGRect:
                return "origin=(\(rect.origin.x), \(rect.origin.y)) size=(\(rect.width) x \(rect.height))"

            case let array as [Any]:
                return array.map { formatValue($0) }.joined(separator: ", ")

            case let dict as [String: Any]:
                return dict.map { "\($0.key): \(formatValue($0.value))" }.joined(separator: ", ")

            default:
                return String(describing: value)
            }
        }

        private func formatValueForJSON(_ value: Any) -> Any {
            switch value {
            case let element as Accessibility.Element:
                var dict: [String: Any] = ["_type": "element"]
                if let role: String = try? element.attribute(.init("AXRole"))() {
                    dict["role"] = role
                }
                if let title: String = try? element.attribute(.init("AXTitle"))() {
                    dict["title"] = title
                }
                if let id: String = try? element.attribute(.init("AXIdentifier"))() {
                    dict["identifier"] = id
                }
                return dict

            case let elements as [Accessibility.Element]:
                return elements.map { formatValueForJSON($0) }

            case let structValue as Accessibility.Struct:
                switch structValue {
                case .point(let point):
                    return ["x": point.x, "y": point.y]
                case .size(let size):
                    return ["width": size.width, "height": size.height]
                case .rect(let rect):
                    return ["x": rect.origin.x, "y": rect.origin.y, "width": rect.width, "height": rect.height]
                case .range(let range):
                    return ["start": range.lowerBound, "end": range.upperBound]
                case .error(let error):
                    return ["error": String(describing: error)]
                }

            case let point as CGPoint:
                return ["x": point.x, "y": point.y]

            case let size as CGSize:
                return ["width": size.width, "height": size.height]

            case let rect as CGRect:
                return [
                    "x": rect.origin.x,
                    "y": rect.origin.y,
                    "width": rect.width,
                    "height": rect.height
                ]

            case let array as [Any]:
                return array.map { formatValueForJSON($0) }

            case let dict as [String: Any]:
                return dict.mapValues { formatValueForJSON($0) }

            case let str as String:
                return str

            case let num as NSNumber:
                return num

            case let bool as Bool:
                return bool

            default:
                return String(describing: value)
            }
        }
    }
}

extension AXDump {
    struct Observe: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Observe accessibility notifications for an application",
            discussion: """
                Monitor accessibility notifications in real-time. Each notification is printed
                with a timestamp. Press Ctrl+C to stop observing.

                COMMON NOTIFICATIONS:
                  AXValueChanged              - Element value changed
                  AXFocusedUIElementChanged   - Focus moved to different element
                  AXFocusedWindowChanged      - Different window got focus
                  AXSelectedTextChanged       - Text selection changed
                  AXSelectedChildrenChanged   - Child selection changed
                  AXWindowCreated/Moved/Resized - Window events
                  AXMenuOpened/Closed         - Menu events
                  AXApplicationActivated      - App became frontmost

                Use -n list to see all common notifications.

                EXAMPLES:
                  axdump observe 710                          Observe focus changes (default)
                  axdump observe 710 -n list                  List available notifications
                  axdump observe 710 -n AXValueChanged        Observe value changes
                  axdump observe 710 -n ValueChanged,Focused  Multiple (AX prefix optional)
                  axdump observe 710 -n all                   Observe all notifications
                  axdump observe 710 -n all -v                Verbose (show element details)
                  axdump observe 710 -w -n AXWindowMoved      Observe from focused window
                  axdump observe 710 -n all -j                JSON output
                """
        )

        @Argument(help: "Process ID of the application")
        var pid: Int32

        @Option(name: [.customShort("n"), .long], help: "Notification(s) to observe (comma-separated, e.g., 'AXValueChanged,AXFocusedUIElementChanged'). Use 'list' to show common notifications, 'all' to observe all available.")
        var notifications: String = "AXFocusedUIElementChanged"

        @Option(name: [.customShort("p"), .long], help: "Path to element to observe (dot-separated child indices)")
        var path: String?

        @Flag(name: [.customShort("F"), .long], help: "Observe focused element")
        var focused: Bool = false

        @Flag(name: .shortAndLong, help: "Observe focused window")
        var window: Bool = false

        @Flag(name: [.customShort("j"), .long], help: "Output as JSON")
        var json: Bool = false

        @Flag(name: [.customShort("v"), .long], help: "Verbose output (show element details)")
        var verbose: Bool = false

        @Flag(name: .long, help: "Disable colored output")
        var noColor: Bool = false

        // ANSI color codes
        private enum Color: String {
            case reset = "\u{001B}[0m"
            case dim = "\u{001B}[2m"
            case bold = "\u{001B}[1m"
            case red = "\u{001B}[31m"
            case green = "\u{001B}[32m"
            case yellow = "\u{001B}[33m"
            case blue = "\u{001B}[34m"
            case magenta = "\u{001B}[35m"
            case cyan = "\u{001B}[36m"
            case white = "\u{001B}[37m"
            case brightRed = "\u{001B}[91m"
            case brightGreen = "\u{001B}[92m"
            case brightYellow = "\u{001B}[93m"
            case brightBlue = "\u{001B}[94m"
            case brightMagenta = "\u{001B}[95m"
            case brightCyan = "\u{001B}[96m"
        }

        private func colorForNotification(_ name: String) -> Color {
            switch name {
            case "AXValueChanged", "AXSelectedTextChanged":
                return .green
            case "AXFocusedUIElementChanged", "AXFocusedWindowChanged":
                return .cyan
            case "AXLayoutChanged", "AXResized", "AXMoved":
                return .yellow
            case "AXWindowCreated", "AXWindowMoved", "AXWindowResized":
                return .blue
            case "AXApplicationActivated", "AXApplicationDeactivated":
                return .magenta
            case "AXMenuOpened", "AXMenuClosed", "AXMenuItemSelected":
                return .brightMagenta
            case "AXUIElementDestroyed":
                return .red
            case "AXCreated":
                return .brightGreen
            case "AXTitleChanged":
                return .brightCyan
            default:
                return .white
            }
        }

        // Common notifications
        static let commonNotifications = [
            "AXValueChanged",
            "AXUIElementDestroyed",
            "AXSelectedTextChanged",
            "AXSelectedChildrenChanged",
            "AXFocusedUIElementChanged",
            "AXFocusedWindowChanged",
            "AXApplicationActivated",
            "AXApplicationDeactivated",
            "AXWindowCreated",
            "AXWindowMoved",
            "AXWindowResized",
            "AXWindowMiniaturized",
            "AXWindowDeminiaturized",
            "AXDrawerCreated",
            "AXSheetCreated",
            "AXMenuOpened",
            "AXMenuClosed",
            "AXMenuItemSelected",
            "AXTitleChanged",
            "AXResized",
            "AXMoved",
            "AXCreated",
            "AXLayoutChanged",
            "AXSelectedCellsChanged",
            "AXUnitsChanged",
            "AXSelectedColumnsChanged",
            "AXSelectedRowsChanged",
            "AXRowCountChanged",
            "AXRowExpanded",
            "AXRowCollapsed",
        ]

        func run() throws {
            guard Accessibility.isTrusted(shouldPrompt: true) else {
                print("Error: Accessibility permissions required")
                throw ExitCode.failure
            }

            // Handle 'list' option
            if notifications.lowercased() == "list" {
                print("Common Accessibility Notifications:")
                print(String(repeating: "-", count: 40))
                for notification in Self.commonNotifications {
                    print("  \(notification)")
                }
                return
            }

            let appElement = Accessibility.Element(pid: pid)

            // Determine target element
            var targetElement: Accessibility.Element = appElement

            if focused {
                guard let focusedElement: Accessibility.Element = try? appElement.attribute(.init("AXFocusedUIElement"))() else {
                    print("Error: Could not get focused element for PID \(pid)")
                    throw ExitCode.failure
                }
                targetElement = focusedElement
            } else if window {
                guard let focusedWindow: Accessibility.Element = try? appElement.attribute(.init("AXFocusedWindow"))() else {
                    print("Error: Could not get focused window for PID \(pid)")
                    throw ExitCode.failure
                }
                targetElement = focusedWindow
            }

            // Navigate via path if specified
            if let pathString = path {
                targetElement = try navigateToPath(from: targetElement, path: pathString)
            }

            // Print element info
            printElementInfo(targetElement)

            // Determine which notifications to observe
            let notificationNames: [String]
            if notifications.lowercased() == "all" {
                notificationNames = Self.commonNotifications
            } else {
                notificationNames = notifications.split(separator: ",")
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                    .map { $0.hasPrefix("AX") ? $0 : "AX\($0)" }
            }

            print("Observing notifications: \(notificationNames.joined(separator: ", "))")
            print("Press Ctrl+C to stop")
            print(String(repeating: "=", count: 60))
            print()

            // Create observer
            let observer = try Accessibility.Observer(pid: pid, on: .main)

            // Store tokens to keep observations alive
            var tokens: [Accessibility.Observer.Token] = []

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss.SSS"

            for notificationName in notificationNames {
                do {
                    let token = try observer.observe(
                        .init(notificationName),
                        for: targetElement
                    ) { [self] info in
                        let timestamp = dateFormatter.string(from: Date())

                        if json {
                            var output: [String: Any] = [
                                "timestamp": timestamp,
                                "notification": notificationName
                            ]

                            if let element = info["AXUIElement"] as? Accessibility.Element {
                                output["element"] = formatElementForJSON(element)
                                let pathInfo = computeElementPath(element, appElement: appElement)
                                output["path"] = pathInfo.path
                                output["chain"] = pathInfo.chain
                            }

                            if let jsonData = try? JSONSerialization.data(withJSONObject: output, options: [.sortedKeys]),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                print(jsonString)
                            }
                        } else {
                            let useColor = !noColor
                            let c = { (color: Color) -> String in useColor ? color.rawValue : "" }
                            let notifColor = colorForNotification(notificationName)

                            var line = "\(c(.dim))[\(timestamp)]\(c(.reset)) "
                            line += "\(c(notifColor))\(notificationName)\(c(.reset))"

                            if let element = info["AXUIElement"] as? Accessibility.Element {
                                let pathInfo = computeElementPath(element, appElement: appElement)
                                line += " \(c(.dim))@\(c(.reset)) \(c(.blue))\(pathInfo.path)\(c(.reset))"
                                if verbose {
                                    line += "\n    \(c(.dim))chain:\(c(.reset)) \(c(.magenta))\(pathInfo.chain)\(c(.reset))"
                                    line += "\n    \(c(.dim))element:\(c(.reset)) \(formatElementColored(element, useColor: useColor))"
                                }
                            } else {
                                line += " \(c(.dim))(no element)\(c(.reset))"
                            }

                            print(line)
                        }

                        // Flush output immediately
                        fflush(stdout)
                    }
                    tokens.append(token)
                } catch {
                    if verbose {
                        print("Warning: Could not observe \(notificationName): \(error)")
                    }
                }
            }

            if tokens.isEmpty {
                print("Error: Could not register for any notifications")
                throw ExitCode.failure
            }

            print("Successfully registered for \(tokens.count) notification(s)")
            print()

            // Keep running
            RunLoop.main.run()
        }

        private func navigateToPath(from element: Accessibility.Element, path: String) throws -> Accessibility.Element {
            var current = element
            let indices = path.split(separator: ".").compactMap { Int($0) }

            for (step, index) in indices.enumerated() {
                let childrenAttr: Accessibility.Attribute<[Accessibility.Element]> = current.attribute(.init("AXChildren"))
                guard let children: [Accessibility.Element] = try? childrenAttr() else {
                    throw ValidationError("Element at step \(step) has no children")
                }
                guard index >= 0 && index < children.count else {
                    throw ValidationError("Child index \(index) at step \(step) out of range (0..<\(children.count))")
                }
                current = children[index]
            }

            return current
        }

        private func printElementInfo(_ element: Accessibility.Element) {
            print("Observing Element:")
            print(String(repeating: "-", count: 40))

            if let role: String = try? element.attribute(.init("AXRole"))() {
                print("Role: \(role)")
            }
            if let title: String = try? element.attribute(.init("AXTitle"))() {
                print("Title: \(title)")
            }
            if let id: String = try? element.attribute(.init("AXIdentifier"))() {
                print("Identifier: \(id)")
            }

            print()
        }

        private func formatElement(_ element: Accessibility.Element) -> String {
            formatElementColored(element, useColor: false)
        }

        private func formatElementColored(_ element: Accessibility.Element, useColor: Bool) -> String {
            let c = { (color: Color) -> String in useColor ? color.rawValue : "" }
            var parts: [String] = []

            if let role: String = try? element.attribute(.init("AXRole"))() {
                parts.append("\(c(.cyan))role\(c(.reset))=\(c(.white))\(role)\(c(.reset))")
            }
            if let title: String = try? element.attribute(.init("AXTitle"))() {
                let truncated = title.count > 30 ? String(title.prefix(30)) + "..." : title
                parts.append("\(c(.yellow))title\(c(.reset))=\"\(c(.white))\(truncated)\(c(.reset))\"")
            }
            if let id: String = try? element.attribute(.init("AXIdentifier"))() {
                parts.append("\(c(.green))id\(c(.reset))=\"\(c(.white))\(id)\(c(.reset))\"")
            }
            if let value: Any = try? element.attribute(.init("AXValue"))() {
                let strValue = String(describing: value)
                let truncated = strValue.count > 30 ? String(strValue.prefix(30)) + "..." : strValue
                parts.append("\(c(.magenta))value\(c(.reset))=\"\(c(.white))\(truncated)\(c(.reset))\"")
            }

            return parts.isEmpty ? "(element)" : parts.joined(separator: " ")
        }

        /// Compute the path from the application root to the given element
        /// Returns a tuple of (indexPath, chainDescription)
        /// indexPath is like "0.2.1" and chainDescription shows the hierarchy with roles/ids
        private func computeElementPath(_ element: Accessibility.Element, appElement: Accessibility.Element) -> (path: String, chain: String) {
            // Walk up the hierarchy collecting ancestors
            var ancestors: [Accessibility.Element] = []
            var current = element

            while true {
                ancestors.append(current)
                guard let parent: Accessibility.Element = try? current.attribute(.init("AXParent"))() else {
                    break
                }
                // Stop if we've reached the application element
                if parent == appElement {
                    break
                }
                current = parent
            }

            // Reverse to get root-to-element order (excluding app element itself)
            ancestors.reverse()

            // Now compute indices by finding each element's index in its parent's children
            var indices: [Int] = []
            var chainParts: [String] = []

            // Start from appElement and find indices
            var parentForIndex = appElement
            for ancestor in ancestors {
                // Get children of parent
                let childrenAttr: Accessibility.Attribute<[Accessibility.Element]> = parentForIndex.attribute(.init("AXChildren"))
                if let children: [Accessibility.Element] = try? childrenAttr() {
                    if let index = children.firstIndex(of: ancestor) {
                        indices.append(index)
                    } else {
                        indices.append(-1) // Unknown index
                    }
                } else {
                    indices.append(-1)
                }

                // Build chain description for this element
                var desc = ""
                if let role: String = try? ancestor.attribute(.init("AXRole"))() {
                    desc = role.replacingOccurrences(of: "AX", with: "")
                }
                if let id: String = try? ancestor.attribute(.init("AXIdentifier"))() {
                    desc += "[\(id)]"
                } else if let title: String = try? ancestor.attribute(.init("AXTitle"))() {
                    let truncated = title.count > 20 ? String(title.prefix(20)) + "..." : title
                    desc += "[\"\(truncated)\"]"
                }
                if desc.isEmpty {
                    desc = "?"
                }
                chainParts.append(desc)

                parentForIndex = ancestor
            }

            let pathString = indices.map { $0 >= 0 ? String($0) : "?" }.joined(separator: ".")
            let chainString = chainParts.joined(separator: " > ")

            return (pathString, chainString)
        }

        private func formatElementForJSON(_ element: Accessibility.Element) -> [String: Any] {
            var dict: [String: Any] = [:]

            if let role: String = try? element.attribute(.init("AXRole"))() {
                dict["role"] = role
            }
            if let title: String = try? element.attribute(.init("AXTitle"))() {
                dict["title"] = title
            }
            if let id: String = try? element.attribute(.init("AXIdentifier"))() {
                dict["identifier"] = id
            }
            if let value: Any = try? element.attribute(.init("AXValue"))() {
                dict["value"] = String(describing: value)
            }

            return dict
        }
    }
}

AXDump.main()
