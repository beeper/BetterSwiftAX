import Foundation
import ApplicationServices

extension Accessibility {
    public enum Struct: AccessibilityConvertible {
        case point(CGPoint)
        case size(CGSize)
        case rect(CGRect)
        case range(Range<Int>)
        case error(AccessibilityError)
        // case illegal -- represented by nil

        public var kind: AXValueType {
            switch self {
            case .point: return .cgPoint
            case .size: return .cgSize
            case .rect: return .cgRect
            case .range: return .cfRange
            case .error: return .axError
            }
        }

        public func raw() -> AXValue? {
            switch self {
            case .point(var point):
                return AXValueCreate(kind, &point)
            case .size(var size):
                return AXValueCreate(kind, &size)
            case .rect(var rect):
                return AXValueCreate(kind, &rect)
            case .range(let range):
                var cfRange = CFRange(location: range.startIndex, length: range.count)
                return AXValueCreate(kind, &cfRange)
            case .error(let error):
                var code = error.code
                return AXValueCreate(kind, &code)
            }
        }

        public func axRaw() -> AnyObject? { raw() }

        init?(_ value: AXValue) {
            let kind = AXValueGetType(value)
            switch kind {
            case .illegal:
                return nil
            case .cgPoint:
                var point = CGPoint()
                guard AXValueGetValue(value, kind, &point) else { return nil }
                self = .point(point)
            case .cgSize:
                var size = CGSize()
                guard AXValueGetValue(value, kind, &size) else { return nil }
                self = .size(size)
            case .cgRect:
                var rect = CGRect()
                guard AXValueGetValue(value, kind, &rect) else { return nil }
                self = .rect(rect)
            case .cfRange:
                var range = CFRange()
                guard AXValueGetValue(value, kind, &range), range.length >= 0 else { return nil }
                let (upperBound, overflow) = range.location.addingReportingOverflow(range.length)
                guard !overflow else { return nil }
                self = .range(range.location..<upperBound)
            case .axError:
                var err: AXError = .success
                guard AXValueGetValue(value, kind, &err) else { return nil }
                self = .error(.init(err))
            @unknown default:
                return nil
            }
        }

        public init?(erased object: CFTypeRef) {
            guard CFGetTypeID(object) == AXValueGetTypeID() else {
                return nil
            }
            self.init(object as! AXValue)
        }

        public init?(axRaw: AnyObject) {
            self.init(erased: axRaw)
        }
    }
}

extension CGPoint: AccessibilityConvertible {
    public func axRaw() -> AnyObject? {
        Accessibility.Struct.point(self).axRaw()
    }
    public init?(axRaw: AnyObject) {
        guard case let .point(value) = Accessibility.Struct(axRaw: axRaw) else {
            return nil
        }
        self = value
    }
}

extension CGSize: AccessibilityConvertible {
    public func axRaw() -> AnyObject? {
        Accessibility.Struct.size(self).axRaw()
    }
    public init?(axRaw: AnyObject) {
        guard case let .size(value) = Accessibility.Struct(axRaw: axRaw) else {
            return nil
        }
        self = value
    }
}

extension CGRect: AccessibilityConvertible {
    public func axRaw() -> AnyObject? {
        Accessibility.Struct.rect(self).axRaw()
    }
    public init?(axRaw: AnyObject) {
        guard case let .rect(value) = Accessibility.Struct(axRaw: axRaw) else {
            return nil
        }
        self = value
    }
}

extension Range: AccessibilityConvertible where Bound == Int {
    public func axRaw() -> AnyObject? {
        Accessibility.Struct.range(self).axRaw()
    }
    public init?(axRaw: AnyObject) {
        guard case let .range(value) = Accessibility.Struct(axRaw: axRaw) else {
            return nil
        }
        self = value
    }
}

extension AccessibilityError: AccessibilityConvertible {
    public func axRaw() -> AnyObject? {
        Accessibility.Struct.error(self).axRaw()
    }
    public init?(axRaw: AnyObject) {
        guard case let .error(value) = Accessibility.Struct(axRaw: axRaw) else {
            return nil
        }
        self = value
    }
}
