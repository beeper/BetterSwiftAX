import ApplicationServices

// Extracted from: System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXAttributeConstants.h, System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXWebConstants.h

extension Accessibility {
    public enum AttributeKey {
        // MARK: - Informational Attributes

        /**
         * Abstract:
         * Identifies the basic type of an element.
         *
         * Value:
         * A CFStringRef of one of the role strings defined in this header, or a new
         * role string of your own invention. The string should not be localized, and it does
         * not need to be human-readable. Instead of inventing new role strings, see if a
         * custom element can be identified by an existing role string and a new subrole. See
         * kAXSubroleAttribute.
         *
         * Writable:
         * No
         *
         * Discussion:
         * Required for all elements. Even in the worst case scenario where an element cannot
         * figure out what its basic type is, it can still supply the value kAXUnknownRole.
         *
         * Carbon Accessorization Notes:
         * If your HIObjectClass or Carbon Event handler provides
         * the kAXRoleAttribute, it must also provide the kAXRoleDescriptionAttribute.
         */
        public static let role = kAXRoleAttribute
        /**
         * Abstract:
         * More specifically identifies the type of an element beyond the basic type provided
         * by kAXRoleAttribute.
         *
         * Value:
         * A CFStringRef of one of the subrole strings defined in this header, or a new
         * subrole string of your own invention. The string should not be localized, and it does
         * not need to be human-readable.
         *
         * Writable:
         * No
         *
         * Discussion:
         * Required only when an element's kAXRoleAttribute alone doesn't provide an assistive
         * application with enough information to convey the meaning of this element to the user.
         *
         * An example element that offers the kAXSubroleAttribute is a window's close box. Its
         * kAXRoleAttribute value is kAXButtonRole and its kAXSubroleAttribute is
         * kAXCloseButtonSubrole. It is of role kAXButtonRole because it offers no additional
         * actions or attributes above and beyond what other kAXButtonRole elements provide; it
         * was given a subrole in order to allow an assistive app to communicate the close box's
         * semantic difference to the user.
         *
         * Carbon Accessorization Notes:
         * If your HIObjectClass or Carbon Event handler provides
         * the kAXSubroleAttribute, it must also provide the kAXRoleDescriptionAttribute.
         */
        public static let subrole = kAXSubroleAttribute
        /**
         * Discussion:
         * A localized, human-readable string that an assistive application can present to the user
         * as an explanation of an element's basic type or purpose. Examples would be "push button"
         * or "secure text field". The string's language should match the language of the app that
         * the element lives within. The string should be all lower-case and contain no punctuation.
         *
         * Two elements with the same kAXRoleAttribute and kAXSubroleAttribute should have the
         * same kAXRoleDescriptionAttribute.
         *
         * Value:
         * A localized, human-readable CFStringRef
         *
         * Writable:
         * No
         *
         * Abstract:
         * Required for all elements. Even in the worst case scenario where an element cannot
         * figure out what its basic type is, it can still supply the value "unknown".
         *
         * Carbon Accessorization Notes:
         * The HIObjectClass or Carbon Event handler that provides
         * the AXRole and/or AXSubrole for an element is the one that must also handle the
         * AXRoleDescription attribute. If an HIObjectClass or Carbon Event handler does not
         * provide either the AXRole or AXSubrole, it must not provide the AXRoleDescription.
         */
        public static let roleDescription = kAXRoleDescriptionAttribute
        /**
         * Abstract:
         * A localized, human-readable CFStringRef that offers help content for an element.
         *
         * Discussion:
         * This is often the same information that would be provided in a help tag for the element.
         *
         * Recommended for any element that has help data available.
         *
         * Value:
         * A localized, human-readable CFStringRef.
         *
         * Writable:
         * No.
         */
        public static let help = kAXHelpAttribute
        /**
         * Discussion:
         * The localized, human-readable string that is displayed as part of the element's
         * normal visual interface. For example, an OK button's kAXTitleElement is the string
         * "OK", and a menu item's kAXTitleElement is the text of the menu item.
         *
         * Required if the element draws a string as part of its normal visual interface.
         *
         * Value:
         * A localized, human-readable CFStringRef
         *
         * Writable:
         * No
         */
        public static let title = kAXTitleAttribute
        /**
         * A localized, human-readable string that indicates an element's purpose in a way
         * that is slightly more specific than the kAXRoleDescriptionAttribute, but which
         * is less wordy than the kAXHelpAttribute. Typically, the description should be
         * an adjective or short phrase that describes the element's usage. For example,
         * the description of a slider in a font panel might be "font size". The string
         * should be all lower-case and contain no punctuation.
         *
         * Value: A localized, human-readable CFStringRef.
         *
         * Writable? No.
         *
         * Recommended for all elements because it gives the user a concise indication of
         * an element's purpose.
         */
        public static let description = kAXDescriptionAttribute

        // MARK: - Value Attributes

        /**
         * Discussion:
         * A catch-all attribute that represents a user modifiable setting of an element. For
         * example, the contents of an editable text field, the position of a scroll bar thumb,
         * and whether a check box is checked are all communicated by the kAXValueAttribute of
         * their respective elements.
         *
         * Required for many user manipulatable elements, or those whose value state conveys
         * important information.
         *
         * Value:
         * Varies, but will always be the same type for a given kind of element. Each
         * role that offers kAXValueAttribute will specify the type of data that will be used
         * for its value.
         *
         * Writable:
         * Generally yes. However, it does not need to be writable if some other form
         * of direct manipulation is more appropriate for causing a value change. For example,
         * a kAXScrollBar's kAXValueAttribute is writable because it allows an efficient way
         * for the user to get to a specific position in the element being scrolled. By
         * contrast, a kAXCheckBox's kAXValueAttribute is not settable because underlying
         * functionality of the check box widget relies on it being clicked on; therefore, it
         * changes its own kAXValueAttribute appropriately in response to the kAXPressAction.
         *
         * Required for many user manipulatable elements, or those whose value state conveys
         * important information.
         */
        public static let value = kAXValueAttribute
        /**
         * Used to supplement kAXValueAttribute.  This attribute returns a string description that best
         * describes the current value stored in kAXValueAttribute.  This is useful for things like
         * slider where the numeric value in kAXValueAttribute does not always convey enough information
         * about the adjustment made on the slider.  As an example, a color slider that adjusts thru various
         * colors cannot be well-described by the numeric value in existing AXValueAttribute.  This is where
         * the kAXValueDescriptionAttribute comes in handy.  In this example, the developer can provide the
         * color information using this attribute.
         *
         * Value: A localized, human-readable CFStringRef.
         *
         * Writable? No.
         *
         * Recommended for elements that support kAXValueAttribute.
         */
        public static let valueDescription = kAXValueDescriptionAttribute
        /**
         * Only used in conjunction with kAXValueAttribute and kAXMaxValueAttribute, this
         * attribute represents the minimum value that an element can display. This is useful
         * for things like sliders and scroll bars, where the user needs to have an understanding
         * of how much the kAXValueAttribute can vary.
         *
         * Value: Same data type as the element's kAXValueAttribute.
         *
         * Writable? No.
         *
         * Required for many user maniipulatable elements. See kAXValueAttribute for more
         * details.
         */
        public static let minValue = kAXMinValueAttribute
        /**
         * Only used in conjunction with kAXValueAttribute and kAXMinValueAttribute, this
         * attribute represents the maximum value that an element can display. This is useful
         * for things like sliders and scroll bars, where the user needs to have an understanding
         * of how much the kAXValueAttribute can vary.
         *
         * Value: Same data type as the element's kAXValueAttribute.
         *
         * Writable? No.
         *
         * Required for many user maniipulatable elements. See kAXValueAttribute for more
         * details.
         */
        public static let maxValue = kAXMaxValueAttribute
        /**
         * Only used in conjunction with kAXValueAttribute, this attribute represents the amount
         * a value will change in one action on the given element. In particular, it is used on
         * elements of role kAXIncrementorRole in order to give the user an idea of how much its
         * value will change with a single click on the up or down arrow.
         *
         * Value: Same data type as the element's kAXValueAttribute.
         *
         * Writable? No.
         *
         * Recommended for kAXIncrementorRole and other similar elements.
         */
        public static let valueIncrement = kAXValueIncrementAttribute
        /**
         * An array of the allowed values for a slider or other widget that displays
         * a large value range, but which can only be set to a small subset of values
         * within that range.
         *
         * Value: A CFArrayRef of whatever type the element uses for its kAXValueAttribute.
         *
         * Writable? No.
         *
         * Recommended for sliders or other elements that can only be set to a small
         * set of values.
         */
        public static let allowedValues = kAXAllowedValuesAttribute
        /**
         * kAXPlaceholderValueAttribute
         *
         * The value of placeholder text as found in a text field.
         *
         * Value: A CFStringRef.
         *
         * Writable? No.
         *
         * Recommended for text fields and other elements that have a placeholder value.
         */
        public static let placeholderValue = kAXPlaceholderValueAttribute
        public static let insertionPointLineNumber = kAXInsertionPointLineNumberAttribute
        /**
         * kAXFullScreenButtonAttribute
         *
         * A convenience attribute so assistive apps can quickly access a window's full screen
         * button element.
         *
         * Value: An AXUIElementRef of the window's full screen button element.
         *
         * Writable? No.
         *
         * Required for all window elements that have a full screen button.
         */
        public static let fullScreenButton = kAXFullScreenButtonAttribute
        public static let valueWraps = kAXValueWrapsAttribute

        // MARK: - Visual state attributes

        /**
         * Indicates whether the element can be interacted with by the user. For example,
         * a disabled push button's kAXEnabledAttribute will be false.
         *
         * Value: A CFBooleanRef. True means enabled, false means disabled.
         *
         * Writable? No.
         *
         * Required for all views, menus, and menu items. Not required for windows.
         */
        public static let enabled = kAXEnabledAttribute
        /**
         * Indicates whether the element is the current keyboard focus. It should be writable
         * for any element that can accept keyboard focus, though you can only set the value
         * of kAXFocusedAttribute to true. You cannot unfocus an element by setting the value
         * to false. Only one element in a window's entire accessibility hierarchy should be
         * marked as focused.
         *
         * Value: A CFBooleanRef. True means focused, false means not focused.
         *
         * Writable? Yes, for any focusable element. No in all other cases.
         *
         * Required for any focusable element. Not required for other elements, though it is
         * often offered for non-focusable elements in a read-only fashion.
         */
        public static let focused = kAXFocusedAttribute
        /**
         * The global screen position of the top-left corner of an element.
         *
         * Value: An AXValueRef with type kAXValueCGPointType. 0,0 is the top-left
         * corner of the screen that displays the menu bar. The value of the horizontal
         * axis increases to the right. The value of the vertical axis increases
         * downward. Units are points.
         *
         * Writable? Generally no. However, some elements that can be moved by the user
         * through direct manipulation (like windows) should offer a writable position
         * attribute.
         *
         * Required for all elements that are visible on the screen, which is virtually
         * all elements.
         */
        public static let position = kAXPositionAttribute
        /**
         * The vertical and horizontal dimensions of the element.
         *
         * Value: An AXValueRef with type kAXValueCGSizeType. Units are points.
         *
         * Writable? Generally no. However, some elements that can be resized by the user
         * through direct manipulation (like windows) should offer a writable size attribute.
         *
         * Required for all elements that are visible on the screen, which is virtually
         * all elements.
         */
        public static let size = kAXSizeAttribute

        // MARK: - Miscellaneous or role-specific attributes

        /**
         * Indicates that an element is busy. This status conveys
         * that an element is in the process of updating or loading and that
         * new information will be available when the busy state completes.
         *
         * Value: A CFBooleanRef. True means busy, false means not busy.
         *
         * Writable? Yes.
         */
        public static let elementBusy = kAXElementBusyAttribute
        /**
         * An indication of whether an element is drawn and/or interacted with in a
         * vertical or horizontal manner. Elements such as scroll bars and sliders offer
         * the kAXOrientationAttribute.
         *
         * Value: kAXHorizontalOrientationValue, kAXVerticalOrientationValue, or rarely
         * kAXUnknownOrientationValue.
         *
         * Writable? No.
         *
         * Required for scroll bars, sliders, or other elements whose semantic or
         * associative meaning changes based on their orientation.
         */
        public static let orientation = kAXOrientationAttribute
        /**
         * A convenience attribute whose value is an element that is a header for another
         * element. For example, an outline element has a header attribute whose value is
         * a element of role AXGroup that contains the header buttons for each column.
         * Used for things like tables, outlines, columns, etc.
         *
         * Value: An AXUIElementRef whose role varies.
         *
         * Writable? No.
         *
         * Recommended for elements that have header elements contained within them that an
         * assistive application might want convenient access to.
         */
        public static let header = kAXHeaderAttribute
        public static let edited = kAXEditedAttribute
        public static let tabs = kAXTabsAttribute
        public static let horizontalScrollBar = kAXHorizontalScrollBarAttribute
        public static let verticalScrollBar = kAXVerticalScrollBarAttribute
        public static let overflowButton = kAXOverflowButtonAttribute
        public static let filename = kAXFilenameAttribute
        public static let expanded = kAXExpandedAttribute
        public static let selected = kAXSelectedAttribute
        public static let splitters = kAXSplittersAttribute
        public static let nextContents = kAXNextContentsAttribute
        public static let document = kAXDocumentAttribute
        public static let decrementButton = kAXDecrementButtonAttribute
        public static let incrementButton = kAXIncrementButtonAttribute
        public static let previousContents = kAXPreviousContentsAttribute
        /**
         * A convenience attribute so assistive apps can find interesting child elements
         * of a given element, while at the same time avoiding non-interesting child
         * elements. For example, the contents of a scroll area are the children that get
         * scrolled, and not the horizontal and/or vertical scroll bars. The contents of
         * a tab group does not include the tabs themselves.
         *
         * Value: A CFArrayRef of AXUIElementRefs.
         *
         * Writable? No.
         *
         * Recommended for elements that have children that act upon or are separate from
         * other children.
         */
        public static let contents = kAXContentsAttribute
        /**
         * Convenience attribute that yields the incrementor of a time field or date
         * field element.
         *
         * Value: A AXUIElementRef of role kAXIncrementorRole.
         *
         * Writable? No.
         *
         * Required for time field and date field elements that display an incrementor.
         */
        public static let incrementor = kAXIncrementorAttribute
        public static let columnTitle = kAXColumnTitleAttribute
        /**
         * Value: A CFURLRef.
         *
         * Writable? No.
         *
         * Required for elements that represent a disk or network item.
         */
        public static let url = kAXURLAttribute
        public static let labelUIElements = kAXLabelUIElementsAttribute
        public static let labelValue = kAXLabelValueAttribute
        public static let shownMenuUIElement = kAXShownMenuUIElementAttribute
        public static let isApplicationRunning = kAXIsApplicationRunningAttribute
        public static let focusedApplication = kAXFocusedApplicationAttribute
        public static let alternateUIVisible = kAXAlternateUIVisibleAttribute

        // MARK: - Hierarchy or relationship attributes

        /**
         * Indicates the element's container element in the visual element hierarchy. A push
         * button's kAXParentElement might be a window element or a group. A sheet's
         * kAXParentElement will be a window element. A window's kAXParentElement will be the
         * application element. A menu item's kAXParentElement will be a menu element.
         *
         * Value: An AXUIElementRef.
         *
         * Writable? No.
         *
         * Required for every element except the application. Everything else in the visual
         * element hierarchy must have a parent.
         */
        public static let parent = kAXParentAttribute
        /**
         * Indicates the sub elements of a given element in the visual element hierarchy. A tab
         * group's kAXChildrenAttribute is an array of tab radio button elements. A window's
         * kAXChildrenAttribute is an array of the first-order views elements within the window.
         * A menu's kAXChildrenAttribute is an array of the menu item elements.
         *
         * A given element may only be in the child array of one other element. If an element is
         * in the child array of some other element, the element's kAXParentAttribute must be
         * the other element.
         *
         * Value: A CFArrayRef of AXUIElementRefs.
         *
         * Writable? No.
         *
         * Required for elements that contain sub elements.
         */
        public static let children = kAXChildrenAttribute
        /**
         * Indicates the selected sub elements of a given element in the visual element hierarchy.
         * This is a the subset of the element's kAXChildrenAttribute that are selected. This is
         * commonly used in lists so an assistive app can know which list item are selected.
         *
         * Value: A CFArrayRef of AXUIElementRefs.
         *
         * Writable? Only if there is no other way to manipulate the set of selected elements via
         * accessibilty attributes or actions. Even if other ways exist, this attribute can be
         * writable as a convenience to assistive applications and their users. If
         * kAXSelectedChildrenAttribute is writable, a write request with a value of an empty
         * array should deselect all selected children.
         *
         * Required for elements that contain selectable sub elements.
         */
        public static let selectedChildren = kAXSelectedChildrenAttribute
        /**
         * Indicates the visible sub elements of a given element in the visual element hierarchy.
         * This is a the subset of the element's kAXChildrenAttribute that a sighted user can
         * see on the screen. In a list element, kAXVisibleChildrenAttribute would be an array
         * of child elements that are currently scrolled into view.
         *
         * Value: A CFArrayRef of AXUIElementRefs.
         *
         * Writable? No.
         *
         * Recommended for elements whose child elements can be occluded or scrolled out of view.
         */
        public static let visibleChildren = kAXVisibleChildrenAttribute
        /**
         * A short cut for traversing an element's parent hierarchy until an element of role
         * kAXWindowRole is found. Note that the value for kAXWindowAttribute should not be
         * an element of role kAXSheetRole or kAXDrawerRole; instead, the value should be the
         * element of kAXWindowRole that the sheet or drawer is attached to.
         *
         * Value: an AXUIElementRef of role kAXWindowRole.
         *
         * Writable? No.
         *
         * Required for any element that has an element of role kAXWindowRole somewhere
         * in its parent chain.
         */
        public static let window = kAXWindowAttribute
        /**
         * This is very much like the kAXWindowAttribute, except that the value of this
         * attribute can be an element with role kAXSheetRole or kAXDrawerRole. It is
         * a short cut for traversing an element's parent hierarchy until an element of
         * role kAXWindowRole, kAXSheetRole, or kAXDrawerRole is found.
         *
         * Value: An AXUIElementRef of role kAXWindowRole, kAXSheetRole, or kAXDrawerRole.
         *
         * Writable? No.
         *
         * Required for any element that has an appropriate element somewhere in its
         * parent chain.
         */
        public static let topLevelUIElement = kAXTopLevelUIElementAttribute
        /**
         * Returns an array of elements that also have keyboard focus when a given element has
         * keyboard focus. A common usage of this attribute is to report that both a search
         * text field and a list of resulting suggestions share keyboard focus because keyboard
         * events can be handled by either UI element. In this example, the text field would be
         * the first responder and it would report the list of suggestions as an element in the
         * array returned for kAXSharedFocusElementsAttribute.
         *
         * Value: A CFArrayRef of AXUIElementsRefs.
         *
         * Writable? No.
         */
        public static let sharedFocusElements = kAXSharedFocusElementsAttribute
        public static let titleUIElement = kAXTitleUIElementAttribute
        public static let servesAsTitleForUIElements = kAXServesAsTitleForUIElementsAttribute
        public static let linkedUIElements = kAXLinkedUIElementsAttribute

        // MARK: - Text-specific attributes

        /**
         * The selected text of an editable text element.
         *
         * Value: A CFStringRef with the currently selected text of the element.
         *
         * Writable? No.
         *
         * Required for all editable text elements.
         */
        public static let selectedText = kAXSelectedTextAttribute
        /**
         * The range of characters (not bytes) that defines the current selection of an
         * editable text element.
         *
         * Value: An AXValueRef of type kAXValueCFRange.
         *
         * Writable? Yes.
         *
         * Required for all editable text elements.
         */
        public static let selectedTextRange = kAXSelectedTextRangeAttribute
        /**
         * An array of noncontiguous ranges of characters (not bytes) that defines the current selections of an
         * editable text element.
         *
         * Value: A CFArrayRef of kAXValueCFRanges.
         *
         * Writable? Yes.
         *
         * Recommended for text elements that support noncontiguous selections.
         */
        public static let selectedTextRanges = kAXSelectedTextRangesAttribute
        /**
         * The range of characters (not bytes) that are scrolled into view in the editable
         * text element.
         *
         * Value: An AXValueRef of type kAXValueCFRange.
         *
         * Writable? No.
         *
         * Required for elements of role kAXTextAreaRole. Not required for any other
         * elements, including those of role kAXTextFieldRole.
         */
        public static let visibleCharacterRange = kAXVisibleCharacterRangeAttribute
        /**
         * The total number of characters (not bytes) in an editable text element.
         *
         * Value: CFNumberRef
         *
         * Writable? No.
         *
         * Required for editable text elements.
         */
        public static let numberOfCharacters = kAXNumberOfCharactersAttribute
        /**
         * Value: CFArrayRef of AXUIElementRefs
         *
         * Writable? No.
         *
         * Optional?
         */
        public static let sharedTextUIElements = kAXSharedTextUIElementsAttribute
        /**
         * Value: AXValueRef of type kAXValueCFRangeType
         *
         * Writable? No.
         *
         * Optional?
         */
        public static let sharedCharacterRange = kAXSharedCharacterRangeAttribute

        // MARK: - Window, sheet, or drawer-specific attributes

        /**
         * Whether a window is the main document window of an application. For an active
         * app, the main window is the single active document window. For an inactive app,
         * the main window is the single document window which would be active if the app
         * were active. Main does not necessarily imply that the window has key focus.
         *
         * Value: A CFBooleanRef. True means the window is main. False means it is not.
         *
         * Writable? Yes.
         *
         * Required for all window elements.
         */
        public static let main = kAXMainAttribute
        /**
         * Whether a window is currently minimized to the dock.
         *
         * Value: A CFBooleanRef. True means minimized.
         *
         * Writable? Yes.
         *
         * Required for all window elements that can be minimized.
         */
        public static let minimized = kAXMinimizedAttribute
        /**
         * A convenience attribute so assistive apps can quickly access a window's close
         * button element.
         *
         * Value: An AXUIElementRef of the window's close button element.
         *
         * Writable? No.
         *
         * Required for all window elements that have a close button.
         */
        public static let closeButton = kAXCloseButtonAttribute
        /**
         * A convenience attribute so assistive apps can quickly access a window's zoom
         * button element.
         *
         * Value: An AXUIElementRef of the window's zoom button element.
         *
         * Writable? No.
         *
         * Required for all window elements that have a zoom button.
         */
        public static let zoomButton = kAXZoomButtonAttribute
        /**
         * A convenience attribute so assistive apps can quickly access a window's minimize
         * button element.
         *
         * Value: An AXUIElementRef of the window's minimize button element.
         *
         * Writable? No.
         *
         * Required for all window elements that have a minimize button.
         */
        public static let minimizeButton = kAXMinimizeButtonAttribute
        /**
         * A convenience attribute so assistive apps can quickly access a window's toolbar
         * button element.
         *
         * Value: An AXUIElementRef of the window's toolbar button element.
         *
         * Writable? No.
         *
         * Required for all window elements that have a toolbar button.
         */
        public static let toolbarButton = kAXToolbarButtonAttribute
        /**
         * A convenience attribute so assistive apps can quickly access a window's document
         * proxy element.
         *
         * Value: An AXUIElementRef of the window's document proxy element.
         *
         * Writable? No.
         *
         * Required for all window elements that have a document proxy.
         */
        public static let proxy = kAXProxyAttribute
        /**
         * A convenience attribute so assistive apps can quickly access a window's grow
         * area element.
         *
         * Value: An AXUIElementRef of the window's grow area element.
         *
         * Writable? No.
         *
         * Required for all window elements that have a grow area.
         */
        public static let growArea = kAXGrowAreaAttribute
        /**
         * Whether a window is modal.
         *
         * Value: A CFBooleanRef. True means the window is modal.
         *
         * Writable? No.
         *
         * Required for all window elements.
         */
        public static let modal = kAXModalAttribute
        /**
         * A convenience attribute so assistive apps can quickly access a window's default
         * button element, if any.
         *
         * Value: An AXUIElementRef of the window's default button element.
         *
         * Writable? No.
         *
         * Required for all window elements that have a default button.
         */
        public static let defaultButton = kAXDefaultButtonAttribute
        /**
         * A convenience attribute so assistive apps can quickly access a window's cancel
         * button element, if any.
         *
         * Value: An AXUIElementRef of the window's cancel button element.
         *
         * Writable? No.
         *
         * Required for all window elements that have a cancel button.
         */
        public static let cancelButton = kAXCancelButtonAttribute

        // MARK: - Menu or menu item-specific attributes

        public static let menuItemCmdChar = kAXMenuItemCmdCharAttribute
        public static let menuItemCmdVirtualKey = kAXMenuItemCmdVirtualKeyAttribute
        public static let menuItemCmdGlyph = kAXMenuItemCmdGlyphAttribute
        public static let menuItemCmdModifiers = kAXMenuItemCmdModifiersAttribute
        public static let menuItemMarkChar = kAXMenuItemMarkCharAttribute
        public static let menuItemPrimaryUIElement = kAXMenuItemPrimaryUIElementAttribute

        // MARK: - Application element-specific attributes

        public static let menuBar = kAXMenuBarAttribute
        public static let windows = kAXWindowsAttribute
        public static let frontmost = kAXFrontmostAttribute
        public static let hidden = kAXHiddenAttribute
        public static let mainWindow = kAXMainWindowAttribute
        public static let focusedWindow = kAXFocusedWindowAttribute
        public static let focusedUIElement = kAXFocusedUIElementAttribute
        public static let extrasMenuBar = kAXExtrasMenuBarAttribute

        // MARK: - Date/time-specific attributes

        /**
         * Convenience attribute that yields the hour field of a time field element.
         *
         * Value: A AXUIElementRef of role kAXTextFieldRole that is used to edit the
         * hours in a time field element.
         *
         * Writable? No.
         *
         * Required for time field elements that display hours.
         */
        public static let hourField = kAXHourFieldAttribute
        /**
         * Convenience attribute that yields the minute field of a time field element.
         *
         * Value: A AXUIElementRef of role kAXTextFieldRole that is used to edit the
         * minutes in a time field element.
         *
         * Writable? No.
         *
         * Required for time field elements that display minutes.
         */
        public static let minuteField = kAXMinuteFieldAttribute
        /**
         * Convenience attribute that yields the seconds field of a time field element.
         *
         * Value: A AXUIElementRef of role kAXTextFieldRole that is used to edit the
         * seconds in a time field element.
         *
         * Writable? No.
         *
         * Required for time field elements that display seconds.
         */
        public static let secondField = kAXSecondFieldAttribute
        /**
         * Convenience attribute that yields the AM/PM field of a time field element.
         *
         * Value: A AXUIElementRef of role kAXTextFieldRole that is used to edit the
         * AM/PM setting in a time field element.
         *
         * Writable? No.
         *
         * Required for time field elements that displays an AM/PM setting.
         */
        public static let ampmField = kAXAMPMFieldAttribute
        /**
         * Convenience attribute that yields the day field of a date field element.
         *
         * Value: A AXUIElementRef of role kAXTextFieldRole that is used to edit the
         * day in a date field element.
         *
         * Writable? No.
         *
         * Required for date field elements that display days.
         */
        public static let dayField = kAXDayFieldAttribute
        /**
         * Convenience attribute that yields the month field of a date field element.
         *
         * Value: A AXUIElementRef of role kAXTextFieldRole that is used to edit the
         * month in a date field element.
         *
         * Writable? No.
         *
         * Required for date field elements that display months.
         */
        public static let monthField = kAXMonthFieldAttribute
        /**
         * Convenience attribute that yields the year field of a date field element.
         *
         * Value: A AXUIElementRef of role kAXTextFieldRole that is used to edit the
         * year in a date field element.
         *
         * Writable? No.
         *
         * Required for date field elements that display years.
         */
        public static let yearField = kAXYearFieldAttribute

        // MARK: - Table, outline, or browser-specific attributes

        public static let rows = kAXRowsAttribute
        public static let visibleRows = kAXVisibleRowsAttribute
        public static let selectedRows = kAXSelectedRowsAttribute
        public static let columns = kAXColumnsAttribute
        /**
         * Indicates the visible column sub-elements of a kAXBrowserRole element.
         * This is the subset of a browser's kAXColumnsAttribute where each column in the
         * array is one that is currently scrolled into view within the browser. It does
         * not include any columns that are currently scrolled out of view.
         *
         * Value: A CFArrayRef of AXUIElementRefs representing the columns of a browser.
         * The columns will be grandchild elements of the browser, and will generally be
         * of role kAXScrollArea.
         *
         * Writable? No.
         *
         * Required for all browser elements.
         */
        public static let visibleColumns = kAXVisibleColumnsAttribute
        public static let selectedColumns = kAXSelectedColumnsAttribute
        public static let sortDirection = kAXSortDirectionAttribute
        public static let index = kAXIndexAttribute
        public static let disclosing = kAXDisclosingAttribute
        public static let disclosedRows = kAXDisclosedRowsAttribute
        public static let disclosedByRow = kAXDisclosedByRowAttribute
        public static let columnHeaderUIElements = kAXColumnHeaderUIElementsAttribute

        // MARK: - Outline attributes

        public static let disclosureLevel = kAXDisclosureLevelAttribute

        // MARK: - Matte-specific attributes

        public static let matteHole = kAXMatteHoleAttribute
        public static let matteContentUIElement = kAXMatteContentUIElementAttribute

        // MARK: - Ruler-specific attributes

        public static let markerUIElements = kAXMarkerUIElementsAttribute
        public static let units = kAXUnitsAttribute
        public static let unitDescription = kAXUnitDescriptionAttribute
        public static let markerType = kAXMarkerTypeAttribute
        public static let markerTypeDescription = kAXMarkerTypeDescriptionAttribute

        // MARK: - Search field attributes

        public static let searchButton = kAXSearchButtonAttribute
        public static let clearButton = kAXClearButtonAttribute

        // MARK: - Grid attributes

        public static let rowCount = kAXRowCountAttribute
        public static let columnCount = kAXColumnCountAttribute
        public static let orderedByRow = kAXOrderedByRowAttribute

        // MARK: - Level indicator attributes

        public static let warningValue = kAXWarningValueAttribute
        public static let criticalValue = kAXCriticalValueAttribute

        // MARK: - Cell-based table attributes

        public static let selectedCells = kAXSelectedCellsAttribute
        public static let visibleCells = kAXVisibleCellsAttribute
        public static let rowHeaderUIElements = kAXRowHeaderUIElementsAttribute

        // MARK: - Cell attributes

        public static let rowIndexRange = kAXRowIndexRangeAttribute
        public static let columnIndexRange = kAXColumnIndexRangeAttribute

        // MARK: - Layout area attributes

        public static let horizontalUnits = kAXHorizontalUnitsAttribute
        public static let verticalUnits = kAXVerticalUnitsAttribute
        public static let horizontalUnitDescription = kAXHorizontalUnitDescriptionAttribute
        public static let verticalUnitDescription = kAXVerticalUnitDescriptionAttribute
        public static let handles = kAXHandlesAttribute

        // MARK: - Obsolete/unknown attributes

        public static let text = kAXTextAttribute
        public static let visibleText = kAXVisibleTextAttribute
        public static let isEditable = kAXIsEditableAttribute
        public static let columnTitles = kAXColumnTitlesAttribute

        // MARK: - UI element identification attributes

        public static let identifier = kAXIdentifierAttribute

        // MARK: - Attributes

        public static let ariaAtomic = kAXARIAAtomicAttribute
        /**
         * CFNumberRef, 1-based
         */
        public static let ariaColumnCount = kAXARIAColumnCountAttribute
        /**
         * CFNumberRef, 1-based
         */
        public static let ariaColumnIndex = kAXARIAColumnIndexAttribute
        /**
         * CFStringRef
         */
        public static let ariaCurrent = kAXARIACurrentAttribute
        /**
         * CFStringRef
         */
        public static let ariaLive = kAXARIALiveAttribute
        /**
         * CFNumberRef, 1-based
         */
        public static let ariaPosInSet = kAXARIAPosInSetAttribute
        /**
         * CFStringRef
         */
        public static let ariaRelevant = kAXARIARelevantAttribute
        /**
         * CFNumberRef, 1-based
         */
        public static let ariaRowCount = kAXARIARowCountAttribute
        /**
         * CFNumberRef, 1-based
         */
        public static let ariaRowIndex = kAXARIARowIndexAttribute
        /**
         * CFNumberRef, 1-based
         */
        public static let ariaSetSize = kAXARIASetSizeAttribute
        /**
         * CFStringRef
         */
        public static let accessKey = kAXAccessKeyAttribute
        /**
         * AXUIElementRef
         */
        public static let activeElement = kAXActiveElementAttribute
        /**
         * CFStringRef
         */
        public static let brailleLabel = kAXBrailleLabelAttribute
        /**
         * CFStringRef
         */
        public static let brailleRoleDescription = kAXBrailleRoleDescriptionAttribute
        /**
         * CFBooleanRef
         */
        public static let caretBrowsingEnabled = kAXCaretBrowsingEnabledAttribute
        /**
         * CFArrayRef of CFStringRef
         */
        public static let domClassList = kAXDOMClassListAttribute
        /**
         * CFStringRef
         */
        public static let domIdentifier = kAXDOMIdentifierAttribute
        /**
         * CFStringRef
         */
        public static let datetimeValue = kAXDatetimeValueAttribute
        /**
         * CFArrayRef of AXUIElementRef
         */
        public static let describedBy = kAXDescribedByAttribute
        /**
         * CFArrayRef of CFStringRef
         */
        public static let dropEffects = kAXDropEffectsAttribute
        /**
         * AXUIElementRef
         */
        public static let editableAncestor = kAXEditableAncestorAttribute
        /**
         * AXTextMarkerRef
         */
        public static let endTextMarker = kAXEndTextMarkerAttribute
        /**
         * CFArrayRef of AXUIElementRef
         */
        public static let errorMessageElements = kAXErrorMessageElementsAttribute
        /**
         * CFBooleanRef
         */
        public static let expandedTextValue = kAXExpandedTextValueAttribute
        /**
         * AXUIElementRef
         */
        public static let focusableAncestor = kAXFocusableAncestorAttribute
        /**
         * CFBooleanRef
         */
        public static let grabbed = kAXGrabbedAttribute
        /**
         * CFBooleanRef
         */
        public static let hasDocumentRoleAncestor = kAXHasDocumentRoleAncestorAttribute
        /**
         * CFBooleanRef
         */
        public static let hasPopup = kAXHasPopupAttribute
        /**
         * CFBooleanRef
         */
        public static let hasWebApplicationAncestor = kAXHasWebApplicationAncestorAttribute
        /**
         * AXUIElementRef
         */
        public static let highestEditableAncestor = kAXHighestEditableAncestorAttribute
        /**
         * CFBooleanRef
         */
        public static let inlineText = kAXInlineTextAttribute
        /**
         * CFRange
         */
        public static let intersectionWithSelectionRange = kAXIntersectionWithSelectionRangeAttribute
        /**
         * CFStringRef
         */
        public static let invalid = kAXInvalidAttribute
        /**
         * CFStringRef
         */
        public static let keyShortcuts = kAXKeyShortcutsAttribute
        /**
         * CFArrayRef of AXUIElementRef
         */
        public static let linkUIElements = kAXLinkUIElementsAttribute
        /**
         * CFBooleanRef
         */
        public static let loaded = kAXLoadedAttribute
        /**
         * CFNumber, double, 0.0 - 1.0
         */
        public static let loadingProgress = kAXLoadingProgressAttribute
        /**
         * AXUIElementRef
         */
        public static let mathBase = kAXMathBaseAttribute
        /**
         * CFStringRef
         */
        public static let mathFencedClose = kAXMathFencedCloseAttribute
        /**
         * CFStringRef
         */
        public static let mathFencedOpen = kAXMathFencedOpenAttribute
        /**
         * AXUIElementRef
         */
        public static let mathFractionDenominator = kAXMathFractionDenominatorAttribute
        /**
         * AXUIElementRef
         */
        public static let mathFractionNumerator = kAXMathFractionNumeratorAttribute
        /**
         * CFNumberRef
         */
        public static let mathLineThickness = kAXMathLineThicknessAttribute
        /**
         * AXUIElementRef
         */
        public static let mathOver = kAXMathOverAttribute
        /**
         * CFArrayRef of CFDictionary
         */
        public static let mathPostscripts = kAXMathPostscriptsAttribute
        /**
         * CFArrayRef of CFDictionary
         */
        public static let mathPrescripts = kAXMathPrescriptsAttribute
        /**
         * AXUIElementRef
         */
        public static let mathRootIndex = kAXMathRootIndexAttribute
        /**
         * CFArrayRef of AXUIElementRef
         */
        public static let mathRootRadicand = kAXMathRootRadicandAttribute
        /**
         * AXUIElementRef
         */
        public static let mathSubscript = kAXMathSubscriptAttribute
        /**
         * AXUIElementRef
         */
        public static let mathSuperscript = kAXMathSuperscriptAttribute
        /**
         * AXUIElementRef
         */
        public static let mathUnder = kAXMathUnderAttribute
        /**
         * CFArrayRef of AXUIElementRef
         */
        public static let owns = kAXOwnsAttribute
        /**
         * CFStringRef
         */
        public static let popupValue = kAXPopupValueAttribute
        /**
         * CFBooleanRef
         */
        public static let preventKeyboardDOMEventDispatch = kAXPreventKeyboardDOMEventDispatchAttribute
        /**
         * AXTextMarkerRangeRef
         */
        public static let selectedTextMarkerRange = kAXSelectedTextMarkerRangeAttribute
        /**
         * AXTextMarkerRef
         */
        public static let startTextMarker = kAXStartTextMarkerAttribute
        /**
         * AXTextMarkerRangeRef
         */
        public static let textInputMarkedTextMarkerRange = kAXTextInputMarkedTextMarkerRangeAttribute
        /**
         * CFBooleanRef
         */
        public static let valueAutofillAvailable = kAXValueAutofillAvailableAttribute

        // MARK: - Attributed string keys

        public static let didSpellCheckString = kAXDidSpellCheckStringAttribute
        /**
         * CFBooleanRef
         */
        public static let highlightString = kAXHighlightStringAttribute
        /**
         * CFBooleanRef
         */
        public static let isSuggestedDeletionString = kAXIsSuggestedDeletionStringAttribute
        /**
         * CFBooleanRef
         */
        public static let isSuggestedInsertionString = kAXIsSuggestedInsertionStringAttribute
        /**
         * CFBooleanRef
         */
        public static let isSuggestionString = kAXIsSuggestionStringAttribute
    }
}
