import ApplicationServices

// Extracted from: System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXValueConstants.h

extension Accessibility {
    public enum Value {
        // MARK: - orientations (see kAXOrientationAttribute in AXAttributeConstants.h)

        public static let horizontalOrientation = kAXHorizontalOrientationValue
        public static let verticalOrientation = kAXVerticalOrientationValue
        public static let unknownOrientation = kAXUnknownOrientationValue

        // MARK: - sort directions (see kAXSortDirectionAttribute in AXAttributeConstants.h)

        public static let ascendingSortDirection = kAXAscendingSortDirectionValue
        public static let descendingSortDirection = kAXDescendingSortDirectionValue
        public static let unknownSortDirection = kAXUnknownSortDirectionValue
    }
}
