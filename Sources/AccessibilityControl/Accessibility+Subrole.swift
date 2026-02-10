import ApplicationServices

// Extracted from: System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXRoleConstants.h, System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXWebConstants.h

extension Accessibility {
    public enum Subrole {
        // MARK: - Standard subroles

        public static let closeButton = kAXCloseButtonSubrole
        public static let minimizeButton = kAXMinimizeButtonSubrole
        public static let zoomButton = kAXZoomButtonSubrole
        public static let toolbarButton = kAXToolbarButtonSubrole
        public static let fullScreenButton = kAXFullScreenButtonSubrole
        public static let secureTextField = kAXSecureTextFieldSubrole
        public static let tableRow = kAXTableRowSubrole
        public static let outlineRow = kAXOutlineRowSubrole
        public static let unknown = kAXUnknownSubrole

        // MARK: - New subroles

        public static let standardWindow = kAXStandardWindowSubrole
        public static let dialog = kAXDialogSubrole
        public static let systemDialog = kAXSystemDialogSubrole
        public static let floatingWindow = kAXFloatingWindowSubrole
        public static let systemFloatingWindow = kAXSystemFloatingWindowSubrole
        public static let decorative = kAXDecorativeSubrole
        public static let incrementArrow = kAXIncrementArrowSubrole
        public static let decrementArrow = kAXDecrementArrowSubrole
        public static let incrementPage = kAXIncrementPageSubrole
        public static let decrementPage = kAXDecrementPageSubrole
        public static let sortButton = kAXSortButtonSubrole
        public static let searchField = kAXSearchFieldSubrole
        public static let timeline = kAXTimelineSubrole
        public static let ratingIndicator = kAXRatingIndicatorSubrole
        public static let contentList = kAXContentListSubrole
        /**
         * superceded by kAXDescriptionListSubrole in OS X 10.9
         */
        public static let definitionList = kAXDefinitionListSubrole
        /**
         * OS X 10.9 and later
         */
        public static let descriptionList = kAXDescriptionListSubrole
        public static let toggle = kAXToggleSubrole
        public static let `switch` = kAXSwitchSubrole

        // MARK: - Dock subroles

        public static let applicationDockItem = kAXApplicationDockItemSubrole
        public static let documentDockItem = kAXDocumentDockItemSubrole
        public static let folderDockItem = kAXFolderDockItemSubrole
        public static let minimizedWindowDockItem = kAXMinimizedWindowDockItemSubrole
        public static let urlDockItem = kAXURLDockItemSubrole
        public static let dockExtraDockItem = kAXDockExtraDockItemSubrole
        public static let trashDockItem = kAXTrashDockItemSubrole
        public static let separatorDockItem = kAXSeparatorDockItemSubrole
        public static let processSwitcherList = kAXProcessSwitcherListSubrole

        // MARK: - Subroles

        public static let applicationAlertDialog = kAXApplicationAlertDialogSubrole
        public static let applicationAlert = kAXApplicationAlertSubrole
        public static let applicationDialog = kAXApplicationDialogSubrole
        public static let applicationGroup = kAXApplicationGroupSubrole
        public static let applicationLog = kAXApplicationLogSubrole
        public static let applicationMarquee = kAXApplicationMarqueeSubrole
        public static let applicationStatus = kAXApplicationStatusSubrole
        public static let applicationTimer = kAXApplicationTimerSubrole
        public static let audio = kAXAudioSubrole
        public static let codeStyleGroup = kAXCodeStyleGroupSubrole
        public static let definition = kAXDefinitionSubrole
        public static let deleteStyleGroup = kAXDeleteStyleGroupSubrole
        public static let details = kAXDetailsSubrole
        public static let documentArticle = kAXDocumentArticleSubrole
        public static let documentMath = kAXDocumentMathSubrole
        public static let documentNote = kAXDocumentNoteSubrole
        public static let emptyGroup = kAXEmptyGroupSubrole
        public static let fieldset = kAXFieldsetSubrole
        public static let fileUploadButton = kAXFileUploadButtonSubrole
        public static let insertStyleGroup = kAXInsertStyleGroupSubrole
        public static let landmarkBanner = kAXLandmarkBannerSubrole
        public static let landmarkComplementary = kAXLandmarkComplementarySubrole
        public static let landmarkContentInfo = kAXLandmarkContentInfoSubrole
        public static let landmarkMain = kAXLandmarkMainSubrole
        public static let landmarkNavigation = kAXLandmarkNavigationSubrole
        public static let landmarkRegion = kAXLandmarkRegionSubrole
        public static let landmarkSearch = kAXLandmarkSearchSubrole
        public static let mathFenceOperator = kAXMathFenceOperatorSubrole
        public static let mathFenced = kAXMathFencedSubrole
        public static let mathFraction = kAXMathFractionSubrole
        public static let mathIdentifier = kAXMathIdentifierSubrole
        public static let mathMultiscript = kAXMathMultiscriptSubrole
        public static let mathNumber = kAXMathNumberSubrole
        public static let mathOperator = kAXMathOperatorSubrole
        public static let mathRoot = kAXMathRootSubrole
        public static let mathRow = kAXMathRowSubrole
        public static let mathSeparatorOperator = kAXMathSeparatorOperatorSubrole
        public static let mathSquareRoot = kAXMathSquareRootSubrole
        public static let mathSubscriptSuperscript = kAXMathSubscriptSuperscriptSubrole
        public static let mathTableCell = kAXMathTableCellSubrole
        public static let mathTableRow = kAXMathTableRowSubrole
        public static let mathTable = kAXMathTableSubrole
        public static let mathText = kAXMathTextSubrole
        public static let mathUnderOver = kAXMathUnderOverSubrole
        public static let meter = kAXMeterSubrole
        public static let rubyInline = kAXRubyInlineSubrole
        public static let rubyText = kAXRubyTextSubrole
        public static let subscriptStyleGroup = kAXSubscriptStyleGroupSubrole
        public static let summary = kAXSummarySubrole
        public static let superscriptStyleGroup = kAXSuperscriptStyleGroupSubrole
        public static let tabPanel = kAXTabPanelSubrole
        public static let term = kAXTermSubrole
        public static let timeGroup = kAXTimeGroupSubrole
        public static let userInterfaceTooltip = kAXUserInterfaceTooltipSubrole
        public static let video = kAXVideoSubrole
        public static let webApplication = kAXWebApplicationSubrole
    }
}
