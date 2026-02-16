import AppKit

final class HighlightOverlayWindow {
    private let window: NSWindow
    private let highlightView: HighlightDrawingView

    init() {
        highlightView = HighlightDrawingView()

        window = NSWindow(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = highlightView
    }

    func highlight(axFrame: CGRect) {
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 0

        // Convert AX coordinates (Y-down from top-left of primary) to
        // Cocoa global coordinates (Y-up from bottom-left of primary)
        let cocoaRect = CGRect(
            x: axFrame.origin.x,
            y: primaryScreenHeight - axFrame.origin.y - axFrame.height,
            width: axFrame.width,
            height: axFrame.height
        )

        // Find the screen that contains this element
        let center = CGPoint(x: cocoaRect.midX, y: cocoaRect.midY)
        let screen = NSScreen.screens.first(where: { $0.frame.contains(center) })
            ?? NSScreen.screens.first!

        // Position the overlay to cover that screen
        if window.frame != screen.frame {
            window.setFrame(screen.frame, display: false)
        }

        // Convert from global Cocoa coords to view-local coords (relative to the screen)
        highlightView.highlightRect = CGRect(
            x: cocoaRect.origin.x - screen.frame.origin.x,
            y: cocoaRect.origin.y - screen.frame.origin.y,
            width: cocoaRect.width,
            height: cocoaRect.height
        )
        highlightView.needsDisplay = true
        window.orderFront(nil)
    }

    func hide() {
        highlightView.highlightRect = nil
        highlightView.needsDisplay = true
        window.orderOut(nil)
    }
}

private class HighlightDrawingView: NSView {
    var highlightRect: CGRect?

    override func draw(_ dirtyRect: NSRect) {
        guard let rect = highlightRect, rect.width > 0, rect.height > 0 else { return }

        let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
        path.lineWidth = 2

        NSColor.controlAccentColor.withAlphaComponent(0.08).setFill()
        path.fill()

        NSColor.controlAccentColor.setStroke()
        path.stroke()
    }
}
