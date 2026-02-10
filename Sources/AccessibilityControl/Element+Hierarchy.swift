import Foundation
import ApplicationServices

// MARK: - Wire Keys

/// Stable IPC protocol keys used by `AXUIElementCopyHierarchy`.
/// These are hardcoded wire values — no runtime resolution needed.
private enum HierarchyWireKey {
    // Option keys
    static let arrayAttributes = "AXCHAA"
    static let skipInspection = "AXCHSIA"
    static let maxArrayCount = "AXCHMAC"
    static let maxDepth = "AXCHMD"
    static let returnErrors = "AXCHRE"
    static let truncateStrings = "AXTRUNC"

    // Result keys
    static let value = "value"
    static let count = "count"
    static let error = "error"
    static let incomplete = "incmplt"
}

// MARK: - dlsym resolution

private typealias AXUIElementCopyHierarchyFn = @convention(c) (
    AXUIElement,
    CFArray,
    CFTypeRef?,
    UnsafeMutablePointer<Unmanaged<CFTypeRef>?>?
) -> AXError

private let _copyHierarchy: AXUIElementCopyHierarchyFn? = {
    guard let sym = dlsym(dlopen(nil, RTLD_NOW), "AXUIElementCopyHierarchy") else {
        return nil
    }
    return unsafeBitCast(sym, to: AXUIElementCopyHierarchyFn.self)
}()

// MARK: - HierarchyOptions

extension Accessibility {
    /// Options for `AXUIElementCopyHierarchy`.
    public struct HierarchyOptions {
        /// Extra array-valued attributes to traverse into (e.g. `kAXChildrenAttribute`).
        public var arrayAttributes: [String]?

        /// Attributes to return values for but NOT recurse into.
        public var skipInspectionAttributes: [String]?

        /// Cap per-attribute array expansion.
        public var maxArrayCount: Int?

        /// Max traversal depth (effect varies by macOS version).
        public var maxDepth: Int?

        /// Include error wrappers for failed attribute fetches.
        public var returnAttributeErrors: Bool?

        /// Truncate string values to 512 characters.
        public var truncateStrings: Bool?

        public init(
            arrayAttributes: [String]? = nil,
            skipInspectionAttributes: [String]? = nil,
            maxArrayCount: Int? = nil,
            maxDepth: Int? = nil,
            returnAttributeErrors: Bool? = nil,
            truncateStrings: Bool? = nil
        ) {
            self.arrayAttributes = arrayAttributes
            self.skipInspectionAttributes = skipInspectionAttributes
            self.maxArrayCount = maxArrayCount
            self.maxDepth = maxDepth
            self.returnAttributeErrors = returnAttributeErrors
            self.truncateStrings = truncateStrings
        }

        fileprivate func toCFDictionary() -> CFDictionary? {
            var dict = [String: Any]()

            if let arrayAttributes {
                dict[HierarchyWireKey.arrayAttributes] = arrayAttributes
            }
            if let skipInspectionAttributes {
                dict[HierarchyWireKey.skipInspection] = skipInspectionAttributes
            }
            if let maxArrayCount {
                dict[HierarchyWireKey.maxArrayCount] = maxArrayCount
            }
            if let maxDepth {
                dict[HierarchyWireKey.maxDepth] = maxDepth
            }
            if let returnAttributeErrors {
                dict[HierarchyWireKey.returnErrors] = returnAttributeErrors
            }
            if let truncateStrings {
                dict[HierarchyWireKey.truncateStrings] = truncateStrings
            }

            guard !dict.isEmpty else { return nil }
            return dict as CFDictionary
        }
    }
}

// MARK: - HierarchyResult

extension Accessibility {
    /// Result of `AXUIElementCopyHierarchy`, wrapping the raw output dictionary.
    ///
    /// The raw dictionary is keyed by `AXUIElementRef` with per-element attribute data as values.
    public struct HierarchyResult {
        /// The raw `NSDictionary` returned by the API.
        public let raw: NSDictionary

        /// Number of element entries in the result.
        public var elementCount: Int { raw.count }

        /// All `AXUIElement` keys as `Element`s.
        public var elements: [Element] {
            raw.allKeys.compactMap { key -> Element? in
                guard CFGetTypeID(key as CFTypeRef) == AXUIElementGetTypeID() else { return nil }
                return Element(raw: key as! AXUIElement)
            }
        }

        /// Look up one element's attribute data.
        public func snapshot(for element: Element) -> ElementSnapshot? {
            guard let perElement = raw[element.raw] as? NSDictionary else { return nil }
            return ElementSnapshot(raw: perElement)
        }

        /// Iterate all element snapshots.
        public func allSnapshots() -> [(element: Element, snapshot: ElementSnapshot)] {
            raw.compactMap { key, value -> (Element, ElementSnapshot)? in
                guard CFGetTypeID(key as CFTypeRef) == AXUIElementGetTypeID(),
                      let perElement = value as? NSDictionary else { return nil }
                return (Element(raw: key as! AXUIElement), ElementSnapshot(raw: perElement))
            }
        }

        // MARK: - ElementSnapshot

        /// Per-element attribute data from a hierarchy result.
        public struct ElementSnapshot {
            fileprivate let raw: NSDictionary

            /// `true` for uninspectable sentinel entries (`{ "incmplt": true }`).
            public var isIncomplete: Bool {
                raw.count == 1
                    && (raw[HierarchyWireKey.incomplete] as? Bool) == true
            }

            /// Look up one attribute by name string.
            public func entry(for attributeName: String) -> AttributeEntry? {
                guard let wrapper = raw[attributeName] as? NSDictionary else { return nil }
                return AttributeEntry(raw: wrapper)
            }

            /// Look up one attribute by typed `Attribute.Name`.
            public func entry<T>(for name: Attribute<T>.Name) -> AttributeEntry? {
                entry(for: name.value)
            }

            /// All attribute names present in this snapshot.
            public var attributeNames: [String] {
                raw.allKeys.compactMap { $0 as? String }
            }
        }

        // MARK: - AttributeEntry

        /// Per-attribute wrapper from a hierarchy result.
        public struct AttributeEntry {
            fileprivate let raw: NSDictionary

            /// The raw value for this attribute.
            public var value: Any? {
                raw[HierarchyWireKey.value]
            }

            /// The value as an array, if it is one.
            public var arrayValue: [Any]? {
                raw[HierarchyWireKey.value] as? [Any]
            }

            /// The value as a string, if it is one.
            public var stringValue: String? {
                raw[HierarchyWireKey.value] as? String
            }

            /// The value as element references, if applicable.
            public var elementValues: [Element]? {
                guard let arr = raw[HierarchyWireKey.value] as? [AnyObject] else { return nil }
                let elements = arr.compactMap { Element(erased: $0 as CFTypeRef) }
                guard elements.count == arr.count else { return nil }
                return elements
            }

            /// True array count (may exceed `arrayValue.count` when capped by `maxArrayCount`).
            public var count: Int? {
                (raw[HierarchyWireKey.count] as? NSNumber)?.intValue
            }

            /// Error code for this attribute (only present with `returnAttributeErrors`).
            public var error: AXError? {
                guard let num = raw[HierarchyWireKey.error] as? NSNumber else { return nil }
                return AXError(rawValue: num.int32Value)
            }

            /// Whether this entry represents an error.
            public var isError: Bool {
                raw[HierarchyWireKey.error] != nil
            }
        }
    }
}

// MARK: - Element.copyHierarchy

extension Accessibility.Element {
    /// Bulk-fetch the accessibility hierarchy in a single IPC round-trip.
    ///
    /// This calls the private `AXUIElementCopyHierarchy` API, which is dramatically faster
    /// than recursively calling `AXUIElementCopyAttributeValue` per element.
    ///
    /// - Parameters:
    ///   - attributes: Attribute names to fetch for each element (e.g. `[kAXRoleAttribute, kAXChildrenAttribute]`).
    ///   - options: Optional configuration for traversal behavior.
    /// - Returns: A `HierarchyResult` containing per-element attribute data.
    /// - Throws: `AccessibilityError` if the call fails, or if the symbol is unavailable.
    public func copyHierarchy(
        requesting attributes: [String],
        options: Accessibility.HierarchyOptions? = nil,
        file: StaticString = #fileID,
        line: UInt = #line
    ) throws -> Accessibility.HierarchyResult {
        guard let fn = _copyHierarchy else {
            throw AccessibilityError(.failure, file: file, line: line)
        }
        var outRef: Unmanaged<CFTypeRef>?
        try Accessibility.check(
            fn(raw, attributes as CFArray, options?.toCFDictionary(), &outRef),
            file: file, line: line
        )
        guard let result = outRef?.takeRetainedValue() as? NSDictionary else {
            throw AccessibilityError(.failure, file: file, line: line)
        }
        return Accessibility.HierarchyResult(raw: result)
    }
}
