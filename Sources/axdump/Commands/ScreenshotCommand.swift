import Foundation
import ArgumentParser
import AccessibilityControl
import WindowControl
import CoreGraphics
import AppKit
import ImageIO

extension AXDump {
    struct Screenshot: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Capture a screenshot of an application window",
            discussion: """
                Captures a window and saves it as a PNG file. Optionally draws bounding boxes
                around specified accessibility elements.

                EXAMPLES:
                  axdump screenshot 710                          Screenshot focused window
                  axdump screenshot 710 -o ~/Desktop/win.png     Custom output path
                  axdump screenshot 710 -i 0                     Screenshot first window
                  axdump screenshot 710 --list                   List available windows
                  axdump screenshot 710 -b 0.1.2                 Draw box around element at path
                  axdump screenshot 710 -b 0.1.2 -b 0.2.0        Multiple bounding boxes
                  axdump screenshot 710 --shadow                 Include window shadow
                """
        )

        @Argument(help: "Process ID of the application")
        var pid: Int32

        @Option(name: [.customShort("o"), .long], help: "Output file path (default: window_<id>.png)")
        var output: String?

        @Option(name: [.customShort("i"), .long], help: "Window index to capture (default: focused window)")
        var windowIndex: Int?

        @Flag(name: .long, help: "List available windows for the application")
        var list: Bool = false

        @Flag(name: .long, help: "Include window shadow in screenshot")
        var shadow: Bool = false

        @Option(name: [.customShort("b"), .long], parsing: .upToNextOption, help: "Element path(s) to draw bounding boxes around")
        var boundingBox: [String] = []

        @Option(name: .long, help: "Bounding box color: red, green, blue, yellow, orange, cyan, magenta, white")
        var boxColor: String = "red"

        @Option(name: .long, help: "Bounding box line width (default: 2.0)")
        var boxWidth: Double = 2.0

        func run() throws {
            guard Accessibility.isTrusted(shouldPrompt: true) else {
                print("Error: Accessibility permissions required")
                throw ExitCode.failure
            }

            let appElement = Accessibility.Element(pid: pid)

            if list {
                try listWindows(appElement)
                return
            }

            // Get the window element
            let windowElement: Accessibility.Element
            if let index = windowIndex {
                let windowsAttr: Accessibility.Attribute<[Accessibility.Element]> = appElement.attribute(.init("AXWindows"))
                guard let windows: [Accessibility.Element] = try? windowsAttr() else {
                    print("Error: Could not get windows for PID \(pid)")
                    throw ExitCode.failure
                }
                guard index >= 0 && index < windows.count else {
                    print("Error: Window index \(index) out of range (0..<\(windows.count))")
                    throw ExitCode.failure
                }
                windowElement = windows[index]
            } else {
                guard let focusedWindow: Accessibility.Element = try? appElement.attribute(.init("AXFocusedWindow"))() else {
                    print("Error: Could not get focused window for PID \(pid)")
                    print("Tip: Use --list to see available windows, then -i <index> to select one")
                    throw ExitCode.failure
                }
                windowElement = focusedWindow
            }

            // Get window ID
            let window: Window
            do {
                window = try windowElement.window()
            } catch {
                print("Error: Could not get window ID: \(error)")
                throw ExitCode.failure
            }

            // Get window bounds for bounding box calculations
            let windowFrame: CGRect = getElementFrame(windowElement) ?? .zero

            // Capture the window
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
                print("Error: Failed to capture window image")
                throw ExitCode.failure
            }

            // Draw bounding boxes if requested
            let finalImage: CGImage
            if !boundingBox.isEmpty {
                finalImage = try drawBoundingBoxes(
                    on: cgImage,
                    windowElement: windowElement,
                    windowFrame: windowFrame,
                    paths: boundingBox
                )
            } else {
                finalImage = cgImage
            }

            // Determine output path
            let outputPath: String
            if let userPath = output {
                outputPath = (userPath as NSString).expandingTildeInPath
            } else {
                outputPath = "window_\(window.raw).png"
            }

            // Save as PNG
            try saveImage(finalImage, to: outputPath)

            print("Screenshot saved to: \(outputPath)")
            print("Window ID: \(window.raw)")
            print("Image size: \(finalImage.width) x \(finalImage.height)")

            if !boundingBox.isEmpty {
                print("Bounding boxes drawn: \(boundingBox.count)")
            }
        }

        private func listWindows(_ appElement: Accessibility.Element) throws {
            let windowsAttr: Accessibility.Attribute<[Accessibility.Element]> = appElement.attribute(.init("AXWindows"))
            guard let windows: [Accessibility.Element] = try? windowsAttr() else {
                print("Error: Could not get windows for PID \(pid)")
                throw ExitCode.failure
            }

            if let appName: String = try? appElement.attribute(.init("AXTitle"))() {
                print("Windows for: \(appName) (PID: \(pid))")
            } else {
                print("Windows for PID: \(pid)")
            }
            print(String(repeating: "-", count: 60))

            if windows.isEmpty {
                print("No windows found")
                return
            }

            let focusedWindow: Accessibility.Element? = try? appElement.attribute(.init("AXFocusedWindow"))()

            for (index, window) in windows.enumerated() {
                var info: [String] = ["[\(index)]"]

                let isFocused = focusedWindow != nil && window == focusedWindow
                if isFocused {
                    info.append("*")
                }

                if let title: String = try? window.attribute(.init("AXTitle"))() {
                    info.append("title=\"\(title)\"")
                }

                if let frame = getElementFrame(window) {
                    info.append("frame=(\(Int(frame.origin.x)),\(Int(frame.origin.y)) \(Int(frame.width))x\(Int(frame.height)))")
                }

                if let windowID = try? window.window() {
                    info.append("id=\(windowID.raw)")
                }

                print(info.joined(separator: " "))
            }

            print()
            print("* = focused window")
            print("Use -i <index> to capture a specific window")
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

        private func drawBoundingBoxes(
            on image: CGImage,
            windowElement: Accessibility.Element,
            windowFrame: CGRect,
            paths: [String]
        ) throws -> CGImage {
            let width = image.width
            let height = image.height

            guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                print("Warning: Could not create graphics context for bounding boxes")
                return image
            }

            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

            let boxCGColor = parseColor(boxColor)
            context.setStrokeColor(boxCGColor)
            context.setLineWidth(CGFloat(boxWidth))

            let scaleX = CGFloat(width) / windowFrame.width
            let scaleY = CGFloat(height) / windowFrame.height

            for path in paths {
                do {
                    let element = try navigateToPath(from: windowElement, path: path)

                    guard let elementFrame = getElementFrame(element) else {
                        print("Warning: Could not get frame for element at path '\(path)'")
                        continue
                    }

                    let relativeX = elementFrame.origin.x - windowFrame.origin.x
                    let relativeY = elementFrame.origin.y - windowFrame.origin.y

                    let imageX = relativeX * scaleX
                    let imageY = relativeY * scaleY
                    let imageWidth = elementFrame.width * scaleX
                    let imageHeight = elementFrame.height * scaleY

                    let flippedY = CGFloat(height) - imageY - imageHeight

                    let rect = CGRect(x: imageX, y: flippedY, width: imageWidth, height: imageHeight)
                    context.stroke(rect)

                    if let role: String = try? element.attribute(.init("AXRole"))() {
                        var desc = "  Box at '\(path)': \(role)"
                        if let title: String = try? element.attribute(.init("AXTitle"))() {
                            desc += " title=\"\(title)\""
                        }
                        desc += " frame=(\(Int(elementFrame.origin.x)),\(Int(elementFrame.origin.y)) \(Int(elementFrame.width))x\(Int(elementFrame.height)))"
                        print(desc)
                    }

                } catch {
                    print("Warning: Could not find element at path '\(path)': \(error)")
                }
            }

            guard let finalImage = context.makeImage() else {
                print("Warning: Could not create final image with bounding boxes")
                return image
            }

            return finalImage
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
            case "white": return CGColor(red: 1, green: 1, blue: 1, alpha: 1)
            default: return CGColor(red: 1, green: 0, blue: 0, alpha: 1)
            }
        }
    }
}

// MARK: - Image Saving Helper

func saveImage(_ image: CGImage, to path: String) throws {
    let url = URL(fileURLWithPath: path)
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        "public.png" as CFString,
        1,
        nil
    ) else {
        throw ImageError.cannotCreateDestination(path)
    }

    CGImageDestinationAddImage(destination, image, nil)

    guard CGImageDestinationFinalize(destination) else {
        throw ImageError.cannotWrite(path)
    }
}

enum ImageError: Error, CustomStringConvertible {
    case cannotCreateDestination(String)
    case cannotWrite(String)

    var description: String {
        switch self {
        case .cannotCreateDestination(let path):
            return "Could not create image destination at \(path)"
        case .cannotWrite(let path):
            return "Failed to write image to \(path)"
        }
    }
}
