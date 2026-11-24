import AppKit

extension NSRect {
    /// Converts a rect between Cocoa coordinates (origin at the bottom-left of the
    /// primary display) and screen/AX coordinates (origin at the top-left of the
    /// primary display, the space used by Accessibility window positions and
    /// CGWindow bounds). The flip is about the primary display's height, so it is
    /// its own inverse and is correct regardless of which display the rect is on.
    @MainActor
    public func flippedBetweenCocoaAndScreenSpace() -> NSRect {
        guard let primaryHeight = NSScreen.screens.first?.frame.height else { return self }
        return NSRect(x: minX, y: primaryHeight - maxY, width: width, height: height)
    }
}
