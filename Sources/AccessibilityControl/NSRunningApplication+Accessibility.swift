import AppKit
import WindowControl
import Cocoa

extension NSRunningApplication {
    public var accessibilityElement: Accessibility.Element {
        .init(pid: self.processIdentifier)
    }
    
    public var accessibilityWindow: WindowControl.Window? {
        try? self.accessibilityElement.window()
    }
}
