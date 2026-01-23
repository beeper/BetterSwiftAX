import Foundation
import ArgumentParser
import AccessibilityControl
import WindowControl
import CoreGraphics
import AppKit

extension AXDump {
    struct Compare: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Screenshot before and after an action",
            discussion: """
                Captures a screenshot of an element, performs an action, then captures
                another screenshot. Useful for understanding how actions affect elements.

                OUTPUT:
                  Creates two files: <name>_before.png and <name>_after.png
                  Default names are based on the action and element path.

                EXAMPLES:
                  axdump compare 710 -a Press -p 0.1.2             Press and compare
                  axdump compare 710 -a Press -F -o toggle         Named output
                  axdump compare 710 -a Increment -p 0.3 -d 500    Wait 500ms between
                  axdump compare 710 -a ShowMenu -F --no-window    Capture element only
                """
        )

        @Argument(help: "Process ID of the application")
        var pid: Int32

        @Option(name: [.customShort("a"), .long], help: "Action to perform (can omit 'AX' prefix)")
        var action: String

        @Option(name: [.customShort("p"), .long], help: "Path to element (dot-separated child indices)")
        var path: String?

        @Option(name: [.customShort("c"), .long], help: "Index of child element")
        var child: Int?

        @Flag(name: [.customShort("F"), .long], help: "Target the focused element")
        var focused: Bool = false

        @Flag(name: .shortAndLong, help: "Target the focused window")
        var window: Bool = false

        @Option(name: [.customShort("o"), .long], help: "Output file prefix (default: <action>_<path>)")
        var output: String?

        @Option(name: [.customShort("d"), .long], help: "Delay in milliseconds between action and after screenshot (default: 100)")
        var delay: Int = 100

        @Flag(name: .long, help: "Only capture the element frame, not the whole window")
        var noWindow: Bool = false

        @Option(name: [.customShort("i"), .long], help: "Window index to capture (default: focused window)")
        var windowIndex: Int?

        @Flag(name: .long, help: "Include window shadow")
        var shadow: Bool = false

        @Option(name: .long, help: "Bounding box color: red, green, blue, yellow, orange, cyan, magenta")
        var boxColor: String = "red"

        func run() throws {
            guard Accessibility.isTrusted(shouldPrompt: true) else {
                print("Error: Accessibility permissions required")
                throw ExitCode.failure
            }

            let appElement = Accessibility.Element(pid: pid)

            // Determine target element for action
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

            if let childIndex = child {
                targetElement = try navigateToChild(from: targetElement, index: childIndex)
            }

            if let pathString = path {
                targetElement = try navigateToPath(from: targetElement, path: pathString)
            }

            // Get the window element for screenshots
            let windowElement: Accessibility.Element
            if let index = windowIndex {
                let windowsAttr: Accessibility.Attribute<[Accessibility.Element]> = appElement.attribute(.init("AXWindows"))
                guard let windows: [Accessibility.Element] = try? windowsAttr() else {
                    print("Error: Could not get windows for PID \(pid)")
                    throw ExitCode.failure
                }
                guard index >= 0 && index < windows.count else {
                    print("Error: Window index \(index) out of range")
                    throw ExitCode.failure
                }
                windowElement = windows[index]
            } else {
                guard let focusedWindow: Accessibility.Element = try? appElement.attribute(.init("AXFocusedWindow"))() else {
                    print("Error: Could not get focused window for PID \(pid)")
                    throw ExitCode.failure
                }
                windowElement = focusedWindow
            }

            // Get window ID
            let cgWindow: Window
            do {
                cgWindow = try windowElement.window()
            } catch {
                print("Error: Could not get window ID: \(error)")
                throw ExitCode.failure
            }

            // Determine output prefix
            let actionName = action.hasPrefix("AX") ? action : "AX\(action)"
            let shortAction = action.replacingOccurrences(of: "AX", with: "")
            let outputPrefix = output ?? "\(shortAction.lowercased())_\(path ?? "focused")"

            // Print info
            print("Compare Action: \(actionName)")
            print("Target Element:")
            printElementInfo(targetElement)

            // Capture before screenshot
            print("Capturing 'before' screenshot...")
            let beforeImage = try captureWindow(cgWindow, element: targetElement, windowElement: windowElement, highlight: true)
            let beforePath = "\(outputPrefix)_before.png"
            try saveImage(beforeImage, to: beforePath)
            print("  Saved: \(beforePath)")

            // Perform action
            print("Performing action: \(actionName)...")
            let axAction = targetElement.action(.init(actionName))
            try axAction()
            print("  Action completed")

            // Wait for UI to update
            if delay > 0 {
                print("  Waiting \(delay)ms...")
                Thread.sleep(forTimeInterval: Double(delay) / 1000.0)
            }

            // Capture after screenshot
            print("Capturing 'after' screenshot...")
            let afterImage = try captureWindow(cgWindow, element: targetElement, windowElement: windowElement, highlight: true)
            let afterPath = "\(outputPrefix)_after.png"
            try saveImage(afterImage, to: afterPath)
            print("  Saved: \(afterPath)")

            // Print summary
            print()
            print("Comparison complete:")
            print("  Before: \(beforePath)")
            print("  After:  \(afterPath)")

            // Print element state change
            print()
            print("Element state after action:")
            printElementInfo(targetElement)
        }

        private func printElementInfo(_ element: Accessibility.Element) {
            if let role: String = try? element.attribute(AXAttribute.role)() {
                print("  Role: \(role)")
            }
            if let title: String = try? element.attribute(AXAttribute.title)() {
                print("  Title: \(title)")
            }
            if let id: String = try? element.attribute(AXAttribute.identifier)() {
                print("  Identifier: \(id)")
            }
            if let value: Any = try? element.attribute(AXAttribute.value)() {
                let strValue = String(describing: value)
                let truncated = strValue.count > 50 ? String(strValue.prefix(50)) + "..." : strValue
                print("  Value: \(truncated)")
            }
            if let enabled: Bool = try? element.attribute(AXAttribute.enabled)() {
                print("  Enabled: \(enabled)")
            }
        }

        private func captureWindow(_ window: Window, element: Accessibility.Element, windowElement: Accessibility.Element, highlight: Bool) throws -> CGImage {
            var imageOptions: CGWindowImageOption = [.boundsIgnoreFraming]
            if shadow {
                imageOptions = []
            }

            guard let cgImage = CGWindowListCreateImage(
                .null,
                .optionIncludingWindow,
                window.raw,
                imageOptions
            ) else {
                throw CompareError.captureFailure
            }

            guard highlight else {
                return cgImage
            }

            // Draw bounding box around target element
            guard let windowFrame = getElementFrame(windowElement),
                  let elementFrame = getElementFrame(element) else {
                return cgImage
            }

            let width = cgImage.width
            let height = cgImage.height

            guard let colorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                return cgImage
            }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            let boxCGColor = parseColor(boxColor)
            context.setStrokeColor(boxCGColor)
            context.setLineWidth(3.0)

            let scaleX = CGFloat(width) / windowFrame.width
            let scaleY = CGFloat(height) / windowFrame.height

            let relativeX = elementFrame.origin.x - windowFrame.origin.x
            let relativeY = elementFrame.origin.y - windowFrame.origin.y

            let imageX = relativeX * scaleX
            let imageY = relativeY * scaleY
            let imageWidth = elementFrame.width * scaleX
            let imageHeight = elementFrame.height * scaleY

            let flippedY = CGFloat(height) - imageY - imageHeight

            let rect = CGRect(x: imageX, y: flippedY, width: imageWidth, height: imageHeight)
            context.stroke(rect)

            return context.makeImage() ?? cgImage
        }

        private func getElementFrame(_ element: Accessibility.Element) -> CGRect? {
            if let frame = try? element.attribute(AXAttribute.frame)() {
                return frame
            }
            if let pos = try? element.attribute(AXAttribute.position)(),
               let size = try? element.attribute(AXAttribute.size)() {
                return CGRect(origin: pos, size: size)
            }
            return nil
        }

        private func parseColor(_ name: String) -> CGColor {
            switch name.lowercased() {
            case "red": return CGColor(red: 1, green: 0, blue: 0, alpha: 1)
            case "green": return CGColor(red: 0, green: 1, blue: 0, alpha: 1)
            case "blue": return CGColor(red: 0, green: 0, blue: 1, alpha: 1)
            case "yellow": return CGColor(red: 1, green: 1, blue: 0, alpha: 1)
            case "orange": return CGColor(red: 1, green: 0.5, blue: 0, alpha: 1)
            case "cyan": return CGColor(red: 0, green: 1, blue: 1, alpha: 1)
            case "magenta": return CGColor(red: 1, green: 0, blue: 1, alpha: 1)
            default: return CGColor(red: 1, green: 0, blue: 0, alpha: 1)
            }
        }
    }
}

enum CompareError: Error, CustomStringConvertible {
    case captureFailure

    var description: String {
        switch self {
        case .captureFailure:
            return "Failed to capture window image"
        }
    }
}
