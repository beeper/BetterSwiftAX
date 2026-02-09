import ApplicationServices

extension Accessibility {
    public enum Subrole {
        public static let `switch` = kAXSwitchSubrole
        public static let closeButton = kAXCloseButtonSubrole
        public static let minimizeButton = kAXMinimizeButtonSubrole
        public static let zoomButton = kAXZoomButtonSubrole
        public static let toolbarButton = kAXToolbarButtonSubrole
        public static let secureTextField = kAXSecureTextFieldSubrole
        public static let tableRow = kAXTableRowSubrole
        public static let outlineRow = kAXOutlineRowSubrole
        public static let unknown = kAXUnknownSubrole
        public static let standardWindow = kAXStandardWindowSubrole
        public static let dialog = kAXDialogSubrole
        public static let systemDialog = kAXSystemDialogSubrole
        public static let floatingWindow = kAXFloatingWindowSubrole
        public static let systemFloatingWindow = kAXSystemFloatingWindowSubrole
        public static let incrementArrow = kAXIncrementArrowSubrole
        public static let decrementArrow = kAXDecrementArrowSubrole
        public static let incrementPage = kAXIncrementPageSubrole
        public static let decrementPage = kAXDecrementPageSubrole
        public static let sortButton = kAXSortButtonSubrole
        public static let searchField = kAXSearchFieldSubrole
        public static let applicationDockItem = kAXApplicationDockItemSubrole
        public static let documentDockItem = kAXDocumentDockItemSubrole
        public static let folderDockItem = kAXFolderDockItemSubrole
        public static let minimizedWindowDockItem = kAXMinimizedWindowDockItemSubrole
        public static let urlDockItem = kAXURLDockItemSubrole
        public static let dockExtraDockItem = kAXDockExtraDockItemSubrole
        public static let trashDockItem = kAXTrashDockItemSubrole
        public static let processSwitcherList = kAXProcessSwitcherListSubrole
    }
}
