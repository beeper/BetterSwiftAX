import AccessibilityControl
import AppKit
import ArgumentParser
import Foundation

@main
struct AXTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Exercise functionality in BetterSwiftAX.",
        subcommands: [Dump.self]
    )
}

extension AXTool {
    struct Dump: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Dump a running app's accessibility hierarchy as XML."
        )

        @Argument(help: "The bundle identifier of the app to target.")
        var bundleID = "com.apple.MobileSMS"

        @Flag(name: [.customShort("s"), .customLong("no-sections")], help: "Skips dumping sections.")
        var excludeSections = false

        @Flag(name: [.customLong("no-actions")], help: "Skips dumping actions.")
        var excludeActions = false

        @Option(name: [.customShort("x"), .customLong("exclude-role")], help: "Skips dumping UI elements with the given role.")
        var excludedRoles = [String]()

        @Option(name: [.customShort("a"), .customLong("exclude-attribute")], help: "Skips dumping the named UI element attribute.")
        var excludedAttributes = Array(XMLDumper.defaultExcludedAttributes)

        @Option(name: [.customShort("d"), .customLong("max-depth")], help: "Skips dumping elements surpassing the specified depth.")
        var maxDepth: Int?

        @Flag(name: [.customShort("p"), .customLong("no-pii")], help: "Attempts to omit PII from the output.")
        var excludingPII = false

        mutating func run() throws {
            guard let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
                throw ValidationError("Found no running applications with the bundle identifier \"\(bundleID)\".")
            }
            let app = Accessibility.Element(pid: runningApp.processIdentifier)

            var output = ""
            print("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>", to: &output)

            try app.dumpXML(
                to: &output,
                maxDepth: maxDepth,
                excludingPII: excludingPII,
                excludingElementsWithRoles: Set(excludedRoles),
                excludingAttributes: Set(excludedAttributes),
                includeActions: !excludeActions,
                includeSections: !excludeSections
            )
            print(output)
        }
    }
}
