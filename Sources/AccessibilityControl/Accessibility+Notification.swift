import ApplicationServices

// Extracted from: System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXNotificationConstants.h, System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXWebConstants.h

public extension Accessibility.Notification {
    // MARK: - Focus Notifications

    /**
     * Abstract:
     * Notification of a change in the main window.
     *
     * Discussion:
     * Value is the new main window UIElement or the
     * Application UIElement if there's no main window.
     */
    static let mainWindowChanged = Self(kAXMainWindowChangedNotification)
    /**
     * Abstract:
     * Notification that the focused window changed.
     */
    static let focusedWindowChanged = Self(kAXFocusedWindowChangedNotification)
    /**
     * Abstract:
     * Notification that the focused UI element has changed.
     *
     * Discussion:
     * Value is the new focused UIElement or
     * the Application UIElement if there's no focus
     */
    static let focusedUIElementChanged = Self(kAXFocusedUIElementChangedNotification)

    // MARK: - Application Notifications

    /**
     * Abstract:
     * Notification that an application was activated.
     *
     * Discussion:
     * Value is an application UIElement.
     */
    static let applicationActivated = Self(kAXApplicationActivatedNotification)
    /**
     * Abstract:
     * Notification that an application was deactivated.
     *
     * Discussion:
     * Value is an application UIElement
     */
    static let applicationDeactivated = Self(kAXApplicationDeactivatedNotification)
    /**
     * Abstract:
     * Notification that an application has been hidden.
     *
     * Discussion:
     * Value is an application UIElement
     */
    static let applicationHidden = Self(kAXApplicationHiddenNotification)
    /**
     * Abstract:
     * Notification that an application is no longer hidden.
     *
     * Discussion:
     * Value is an application UIElement
     */
    static let applicationShown = Self(kAXApplicationShownNotification)

    // MARK: - Window Notifications

    /**
     * Abstract:
     * Notification that a window was created.
     *
     * Discussion:
     * Value is a new window UIElement
     */
    static let windowCreated = Self(kAXWindowCreatedNotification)
    /**
     * Abstract:
     * Notification that a window moved.
     *
     * Discussion:
     * This notification is sent at the end of the window move, not continuously as the window is being moved.
     *
     * Value is the moved window UIElement
     */
    static let windowMoved = Self(kAXWindowMovedNotification)
    /**
     * Abstract:
     * Notification that a window was resized.
     *
     * Discussion:
     * This notification is sent at the end of the window resize, not continuously as the window is being resized.
     *
     * Value is the resized window UIElement
     */
    static let windowResized = Self(kAXWindowResizedNotification)
    /**
     * Abstract:
     * Notification that a window was minimized.
     *
     * Discussion:
     * Value is the minimized window UIElement
     */
    static let windowMiniaturized = Self(kAXWindowMiniaturizedNotification)
    /**
     * Abstract:
     * Notification that a window is no longer minimized.
     *
     * Discussion:
     * Value is the unminimized window UIElement
     */
    static let windowDeminiaturized = Self(kAXWindowDeminiaturizedNotification)

    // MARK: - New Drawer, Sheet, and Help Notifications

    /**
     * Abstract:
     * Notification that a drawer was created.
     */
    static let drawerCreated = Self(kAXDrawerCreatedNotification)
    /**
     * Abstract:
     * Notification that a sheet was created.
     */
    static let sheetCreated = Self(kAXSheetCreatedNotification)
    /**
     * Abstract:
     * Notification that a help tag was created.
     */
    static let helpTagCreated = Self(kAXHelpTagCreatedNotification)

    // MARK: - Element Notifications

    /**
     * Discussion:
     * This notification is sent when the value of the UIElement's <b>value</b> attribute has changed, not when the value of any other attribute has changed.
     *
     * Value is the modified UIElement
     */
    static let valueChanged = Self(kAXValueChangedNotification)
    /**
     * Discussion:
     * The returned UIElement is no longer valid in the target application. You can still use the local reference
     * with calls like CFEqual (for example, to remove it from a list), but you should not pass it to the accessibility APIs.
     *
     * Value is the destroyed UIElement
     */
    static let uiElementDestroyed = Self(kAXUIElementDestroyedNotification)
    /**
     * Abstract:
     * Notification that an element's busy state has changed.
     *
     * Discussion:
     * Value is the (un)busy UIElement.
     */
    static let elementBusyChanged = Self(kAXElementBusyChangedNotification)

    // MARK: - Menu Notifications

    /**
     * Abstract:
     * Notification that a menu has been opened.
     *
     * Discussion:
     * Value is the opened menu UIElement.
     */
    static let menuOpened = Self(kAXMenuOpenedNotification)
    /**
     * Abstract:
     * Notification that a menu has been closed.
     *
     * Discussion:
     * Value is the closed menu UIElement.
     */
    static let menuClosed = Self(kAXMenuClosedNotification)
    /**
     * Abstract:
     * Notification that a menu item has been seleted.
     *
     * Discussion:
     * Value is the selected menu item UIElement.
     */
    static let menuItemSelected = Self(kAXMenuItemSelectedNotification)

    // MARK: - Table/outline notifications

    /**
     * Abstract:
     * Notification that the number of rows in this table has changed.
     */
    static let rowCountChanged = Self(kAXRowCountChangedNotification)

    // MARK: - Outline notifications

    /**
     * Abstract:
     * Notification that a row in an outline has been expanded.
     *
     * Discussion:
     * The value is the collapsed row UIElement.
     */
    static let rowExpanded = Self(kAXRowExpandedNotification)
    /**
     * Abstract:
     * Notification that a row in an outline has been collapsed.
     *
     * Discussion:
     * The value is the collapsed row UIElement.
     */
    static let rowCollapsed = Self(kAXRowCollapsedNotification)

    // MARK: - Cell-based table notifications

    /**
     * Abstract:
     * Notification that the selected cells have changed.
     */
    static let selectedCellsChanged = Self(kAXSelectedCellsChangedNotification)

    // MARK: - Layout area notifications

    /**
     * Abstract:
     * Notification that the units have changed.
     */
    static let unitsChanged = Self(kAXUnitsChangedNotification)
    /**
     * Abstract:
     * Notification that the selected children have moved.
     */
    static let selectedChildrenMoved = Self(kAXSelectedChildrenMovedNotification)

    // MARK: - Other notifications

    /**
     * Abstract:
     * Notification that a different subset of this element's children were selected.
     */
    static let selectedChildrenChanged = Self(kAXSelectedChildrenChangedNotification)
    /**
     * Abstract:
     * Notification that this element has been resized.
     */
    static let resized = Self(kAXResizedNotification)
    /**
     * Abstract:
     * Notification that this element has moved.
     */
    static let moved = Self(kAXMovedNotification)
    /**
     * Abstract:
     * Notification that an element was created.
     */
    static let created = Self(kAXCreatedNotification)
    /**
     * Abstract:
     * Notification that the set of selected rows changed.
     */
    static let selectedRowsChanged = Self(kAXSelectedRowsChangedNotification)
    /**
     * Abstract:
     * Notification that the set of selected columns changed.
     */
    static let selectedColumnsChanged = Self(kAXSelectedColumnsChangedNotification)
    /**
     * Abstract:
     * Notification that a different set of text was selected.
     */
    static let selectedTextChanged = Self(kAXSelectedTextChangedNotification)
    /**
     * Abstract:
     * Notification that the title changed.
     */
    static let titleChanged = Self(kAXTitleChangedNotification)
    /**
     * Abstract:
     * Notification that the layout changed.
     */
    static let layoutChanged = Self(kAXLayoutChangedNotification)
    /**
     * Abstract:
     * Notification to request an announcement to be spoken.
     */
    static let announcementRequested = Self(kAXAnnouncementRequestedNotification)

    // MARK: - Notifications

    static let activeElementChanged = Self(kAXActiveElementChangedNotification)
    static let currentStateChanged = Self(kAXCurrentStateChangedNotification)
    static let expandedChanged = Self(kAXExpandedChangedNotification)
    static let invalidStatusChanged = Self(kAXInvalidStatusChangedNotification)
    static let layoutComplete = Self(kAXLayoutCompleteNotification)
    static let liveRegionChanged = Self(kAXLiveRegionChangedNotification)
    static let liveRegionCreated = Self(kAXLiveRegionCreatedNotification)
    static let loadComplete = Self(kAXLoadCompleteNotification)
}
