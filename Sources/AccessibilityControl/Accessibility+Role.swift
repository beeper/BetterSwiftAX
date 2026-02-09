import ApplicationServices

extension Accessibility {
    // https://developer.apple.com/documentation/applicationservices/carbon_accessibility/roles
    public enum Role {
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
        public static let outline = kAXOutlineRole
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
        public static let cell = kAXCellRole
    }
}
