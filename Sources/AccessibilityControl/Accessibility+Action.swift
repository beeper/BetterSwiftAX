import ApplicationServices

// Extracted from: System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXActionConstants.h

public extension Accessibility.Action.Name {
    // MARK: - Standard Actions

    /**
     * Discussion:
     * Simulate clicking the UIElement, such as a button.
     */
    static let press = Self(kAXPressAction)
    /**
     * Discussion:
     * Increment the value of the UIElement.
     */
    static let increment = Self(kAXIncrementAction)
    /**
     * Discussion:
     * Decrement the value of the UIElement.
     */
    static let decrement = Self(kAXDecrementAction)
    /**
     * Discussion:
     * Simulate pressing Return in the UIElement, such as a text field.
     */
    static let confirm = Self(kAXConfirmAction)
    /**
     * Discussion:
     * Simulate a Cancel action, such as hitting the Cancel button.
     */
    static let cancel = Self(kAXCancelAction)
    /**
     * Discussion:
     * Show alternate or hidden UI.
     * This is often used to trigger the same change that would occur on a mouse hover.
     */
    static let showAlternateUI = Self(kAXShowAlternateUIAction)
    /**
     * Discussion:
     * Show default UI.
     * This is often used to trigger the same change that would occur when a mouse hover ends.
     */
    static let showDefaultUI = Self(kAXShowDefaultUIAction)

    // MARK: - New Actions

    static let raise = Self(kAXRaiseAction)
    static let showMenu = Self(kAXShowMenuAction)

    // MARK: - Obsolete Actions

    /**
     * Discussion:
     * Select the UIElement, such as a menu item.
     */
    static let pick = Self(kAXPickAction)
}
