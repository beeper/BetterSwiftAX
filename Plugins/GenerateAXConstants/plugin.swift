import Foundation
import PackagePlugin

@main
struct GenerateAXConstantsPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let generator = try context.tool(named: "AXConstantsGenerator")

        let outputDir = context.package.directory
            .appending(subpath: "Sources")
            .appending(subpath: "AccessibilityControl")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: generator.path.string)
        process.arguments = [outputDir.string]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            Diagnostics.error("AXConstantsGenerator exited with code \(process.terminationStatus)")
            return
        }
    }
}
