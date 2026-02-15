import AppKit
import WindowControl
import Cocoa

extension NSRunningApplication {
    public var _accessibilityElement: Accessibility.Element {
        .init(pid: self.processIdentifier)
    }
    
    public var _accessibilityWindow: WindowControl.Window? {
        try? self._accessibilityElement.window()
    }
}
