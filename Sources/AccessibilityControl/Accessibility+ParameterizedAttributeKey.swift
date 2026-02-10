import ApplicationServices

// Extracted from: System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXAttributeConstants.h, System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXWebConstants.h

extension Accessibility {
    public enum ParameterizedAttributeKey {
        // MARK: - Text Suite Parameterized Attributes

        public static let lineForIndex = kAXLineForIndexParameterizedAttribute
        public static let rangeForLine = kAXRangeForLineParameterizedAttribute
        public static let stringForRange = kAXStringForRangeParameterizedAttribute
        public static let rangeForPosition = kAXRangeForPositionParameterizedAttribute
        public static let rangeForIndex = kAXRangeForIndexParameterizedAttribute
        public static let boundsForRange = kAXBoundsForRangeParameterizedAttribute
        public static let rtfForRange = kAXRTFForRangeParameterizedAttribute
        public static let attributedStringForRange = kAXAttributedStringForRangeParameterizedAttribute
        public static let styleRangeForIndex = kAXStyleRangeForIndexParameterizedAttribute

        // MARK: - Cell-based table parameterized attributes

        public static let cellForColumnAndRow = kAXCellForColumnAndRowParameterizedAttribute

        // MARK: - Layout area parameterized attributes

        public static let layoutPointForScreenPoint = kAXLayoutPointForScreenPointParameterizedAttribute
        public static let layoutSizeForScreenSize = kAXLayoutSizeForScreenSizeParameterizedAttribute
        public static let screenPointForLayoutPoint = kAXScreenPointForLayoutPointParameterizedAttribute
        public static let screenSizeForLayoutSize = kAXScreenSizeForLayoutSizeParameterizedAttribute

        // MARK: - Parameterized Attributes

        public static let attributedStringForTextMarkerRange = kAXAttributedStringForTextMarkerRangeParameterizedAttribute
        /**
         * (NSValue *) - (rectValue); param: AXTextMarkerRangeRef
         */
        public static let boundsForTextMarkerRange = kAXBoundsForTextMarkerRangeParameterizedAttribute

        // MARK: - (NSValue *) - (rectValue); param: (NSValue *) - (rectValue)

        public static let convertRelativeFrame = kAXConvertRelativeFrameParameterizedAttribute
        /**
         * CFNumberRef; param: AXTextMarkerRef
         */
        public static let indexForTextMarker = kAXIndexForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: AXTextMarkerRef
         */
        public static let leftLineTextMarkerRangeForTextMarker = kAXLeftLineTextMarkerRangeForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: AXTextMarkerRef
         */
        public static let leftWordTextMarkerRangeForTextMarker = kAXLeftWordTextMarkerRangeForTextMarkerParameterizedAttribute
        /**
         * CFNumberRef; param: AXTextMarkerRangeRef
         */
        public static let lengthForTextMarkerRange = kAXLengthForTextMarkerRangeParameterizedAttribute
        /**
         * CFNumberRef; param: AXTextMarkerRef
         */
        public static let lineForTextMarker = kAXLineForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: AXTextMarkerRef
         */
        public static let lineTextMarkerRangeForTextMarker = kAXLineTextMarkerRangeForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: AXTextMarkerRef
         */
        public static let nextLineEndTextMarkerForTextMarker = kAXNextLineEndTextMarkerForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: AXTextMarkerRef
         */
        public static let nextParagraphEndTextMarkerForTextMarker = kAXNextParagraphEndTextMarkerForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: AXTextMarkerRef
         */
        public static let nextSentenceEndTextMarkerForTextMarker = kAXNextSentenceEndTextMarkerForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: AXTextMarkerRef
         */
        public static let nextTextMarkerForTextMarker = kAXNextTextMarkerForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: AXTextMarkerRef
         */
        public static let nextWordEndTextMarkerForTextMarker = kAXNextWordEndTextMarkerForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: AXTextMarkerRef
         */
        public static let paragraphTextMarkerRangeForTextMarker = kAXParagraphTextMarkerRangeForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: AXTextMarkerRef
         */
        public static let previousLineStartTextMarkerForTextMarker = kAXPreviousLineStartTextMarkerForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: AXTextMarkerRef
         */
        public static let previousParagraphStartTextMarkerForTextMarker = kAXPreviousParagraphStartTextMarkerForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: AXTextMarkerRef
         */
        public static let previousSentenceStartTextMarkerForTextMarker = kAXPreviousSentenceStartTextMarkerForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: AXTextMarkerRef
         */
        public static let previousTextMarkerForTextMarker = kAXPreviousTextMarkerForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: AXTextMarkerRef
         */
        public static let previousWordStartTextMarkerForTextMarker = kAXPreviousWordStartTextMarkerForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: AXTextMarkerRef
         */
        public static let rightLineTextMarkerRangeForTextMarker = kAXRightLineTextMarkerRangeForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: AXTextMarkerRef
         */
        public static let rightWordTextMarkerRangeForTextMarker = kAXRightWordTextMarkerRangeForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: AXTextMarkerRef
         */
        public static let sentenceTextMarkerRangeForTextMarker = kAXSentenceTextMarkerRangeForTextMarkerParameterizedAttribute
        /**
         * CFStringRef; param: AXTextMarkerRef
         */
        public static let stringForTextMarkerRange = kAXStringForTextMarkerRangeParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: AXTextMarkerRef
         */
        public static let styleTextMarkerRangeForTextMarker = kAXStyleTextMarkerRangeForTextMarkerParameterizedAttribute
        /**
         * AXTextMarkerRef; param: CFNumberRef
         */
        public static let textMarkerForIndex = kAXTextMarkerForIndexParameterizedAttribute

        // MARK: - AXTextMarkerRef; param: (NSValue *) - (pointValue)

        public static let textMarkerForPosition = kAXTextMarkerForPositionParameterizedAttribute
        /**
         * CFBooleanRef; param: AXTextMarkerRef
         */
        public static let textMarkerIsValid = kAXTextMarkerIsValidParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: CFNumberRef
         */
        public static let textMarkerRangeForLine = kAXTextMarkerRangeForLineParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: AXUIElementRef
         */
        public static let textMarkerRangeForUIElement = kAXTextMarkerRangeForUIElementParameterizedAttribute
        /**
         * AXTextMarkerRangeRef; param: CFArrayRef of AXTextMarkerRef
         */
        public static let textMarkerRangeForUnorderedTextMarkers = kAXTextMarkerRangeForUnorderedTextMarkersParameterizedAttribute
        /**
         * AXUIElementRef; param: AXTextMarkerRef
         */
        public static let uiElementForTextMarker = kAXUIElementForTextMarkerParameterizedAttribute
    }
}
