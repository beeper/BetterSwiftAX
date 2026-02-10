import ApplicationServices

// Extracted from: System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXRoleConstants.h, System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXWebConstants.h

extension Accessibility {
    public enum Role {
        // MARK: - Standard Roles

        public static let application = kAXApplicationRole
        public static let systemWide = kAXSystemWideRole
        public static let window = kAXWindowRole
        public static let sheet = kAXSheetRole
        public static let drawer = kAXDrawerRole
        public static let growArea = kAXGrowAreaRole
        public static let image = kAXImageRole
        public static let unknown = kAXUnknownRole
        public static let button = kAXButtonRole
        public static let radioButton = kAXRadioButtonRole
        public static let checkBox = kAXCheckBoxRole
        public static let popUpButton = kAXPopUpButtonRole
        public static let menuButton = kAXMenuButtonRole
        public static let tabGroup = kAXTabGroupRole
        public static let table = kAXTableRole
        public static let column = kAXColumnRole
        public static let row = kAXRowRole
        /**
         * Discussion:
         * An element that contains row-based data. It may use disclosure triangles to manage the
         * display of hierarchies within the data. It may arrange each row's data into columns and
         * offer a header button above each column. The best example is the list view in a Finder
         * window or Open/Save dialog.
         *
         * Outlines are typically children of AXScrollAreas, which manages the horizontal and/or
         * vertical scrolling for the outline. Outlines are expected to follow certain conventions
         * with respect to their hierarchy of sub-elements. In particular, if the outline uses
         * columns, the data should be accessible via either rows or columns. Thus, the data in a
         * given cell will be represented as two diffrent elements. Here's a hierarchy for a
         * typical outline:
         *
         * <pre>
         * AXScrollArea (parent of the outline)
         * AXScrollBar (if necessary, horizontal)
         * AXScrollBar (if necessary, vertical)
         * AXOutline
         * AXGroup (header buttons, optional)
         * AXButton, AXMenuButton, or <Varies> (header button)
         * ...
         * AXRow (first row)
         * AXStaticText (just one possible example)
         * AXButton (just another possible example)
         * AXTextField (ditto)
         * AXCheckBox (ditto)
         * AXRow (as above)
         * ...
         * AXColumn (first column)
         * AXStaticText (assumes the first column displays text)
         * AXStaticText
         * ...
         * AXColumn (second column)
         * AXButton (assumes the second column displays buttons)
         * AXButton
         * ...
         * ...
         * </pre>
         *
         * Supported attributes:
         *
         * <dl>
         * <dt>AXFocused</dt>
         * <dd>(w)</dd>
         * <dt>AXRows</dt>
         * <dd>Array of subset of AXChildren that are rows</dd>
         * <dt>AXVisibleRows</dt>
         * <dd>Array of subset of AXRows that are visible</dd>
         * <dt>AXSelectedRows</dt>
         * <dd>Array of subset of AXRows that are selected (w)</dd>
         * <dt>AXColumns</dt>
         * <dd>Array of subset of children that are columns</dd>
         * <dt>AXVisibleColumns</dt>
         * <dd>Array of subset of columns that are visible</dd>
         * <dt>AXSelectedColumns</dt>
         * <dd>Array of subset of columns that are selected (o)</dd>
         * <dt>AXHeader</dt>
         * <dd>The AXGroup element that contains the header buttons (o)</dd>
         * </dl>
         */
        public static let outline = kAXOutlineRole
        /**
         * Discussion:
         * An element that contains columns of hierarchical data. Examples include the column view
         * in Finder windows and Open/Save dialogs. Carbon's Data Browser in column view mode
         * represents itself as an AXBrowser. Cocoa's NSBrowser represents itself as an AXBrowser.
         *
         * Browser elements are expected to have a particular hierarchy of sub-elements within it.
         * In particular, the child of an AXBrowser must be an AXScrollArea that manages the
         * horizontal scrolling. The horizontal AXScrollArea must include a child for each column
         * the interface displays. Columns can be any role that makes sense. Typically, columns
         * are vertical AXScrollAreas with AXList children. Here's a hierarchy for a typical
         * browser:
         *
         * <pre>
         * AXBrowser
         * AXScrollArea (manages the horizontal scrolling)
         * AXScrollBar (horizontal scroll bar)
         * AXScrollArea (first column)
         * AXScrollBar (column's vertical scroll bar)
         * AXList (column content is typically a list, but it could be another role)
         * <Varies> (cell)
         * ...
         * <Varies> (cell)
         * AXScrollArea (second column)
         * ...
         * AXScrollArea (third column)
         * ...
         * AXGroup (preview column)
         * ...
         * </pre>
         *
         * Attributes:
         * <ul>
         * <li>AXFocused (w)</li>
         * <li>AXColumns - Array of the grandchild column elements, which are typically
         * of the AXScrollArea role.</li>
         * <li>AXVisibleColumns - Array of the subset of elements in the AXColumns array
         * that are currently visible.</li>
         * <li>AXColumnTitles (o)</li>
         * <li>AXHorizontalScrollBar - The horizontal AXScrollBar of the browser's child
         * AXScrollArea.</li>
         * </ul>
         */
        public static let browser = kAXBrowserRole
        public static let scrollArea = kAXScrollAreaRole
        public static let scrollBar = kAXScrollBarRole
        public static let radioGroup = kAXRadioGroupRole
        public static let list = kAXListRole
        public static let group = kAXGroupRole
        public static let valueIndicator = kAXValueIndicatorRole
        public static let comboBox = kAXComboBoxRole
        public static let slider = kAXSliderRole
        public static let incrementor = kAXIncrementorRole
        public static let busyIndicator = kAXBusyIndicatorRole
        public static let progressIndicator = kAXProgressIndicatorRole
        public static let relevanceIndicator = kAXRelevanceIndicatorRole
        public static let toolbar = kAXToolbarRole
        public static let disclosureTriangle = kAXDisclosureTriangleRole
        public static let textField = kAXTextFieldRole
        public static let textArea = kAXTextAreaRole
        public static let staticText = kAXStaticTextRole
        public static let heading = kAXHeadingRole
        public static let menuBar = kAXMenuBarRole
        public static let menuBarItem = kAXMenuBarItemRole
        public static let menu = kAXMenuRole
        public static let menuItem = kAXMenuItemRole
        public static let splitGroup = kAXSplitGroupRole
        public static let splitter = kAXSplitterRole
        public static let colorWell = kAXColorWellRole
        public static let timeField = kAXTimeFieldRole
        public static let dateField = kAXDateFieldRole
        public static let helpTag = kAXHelpTagRole
        public static let matte = kAXMatteRole
        public static let dockItem = kAXDockItemRole
        public static let ruler = kAXRulerRole
        public static let rulerMarker = kAXRulerMarkerRole
        public static let grid = kAXGridRole
        public static let levelIndicator = kAXLevelIndicatorRole
        public static let cell = kAXCellRole
        public static let layoutArea = kAXLayoutAreaRole
        public static let layoutItem = kAXLayoutItemRole
        public static let handle = kAXHandleRole
        public static let popover = kAXPopoverRole

        // MARK: - Roles

        public static let imageMap = kAXImageMapRole
    }
}
