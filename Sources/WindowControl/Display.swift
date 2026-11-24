import Foundation
import AppKit
import CWindowControl

extension UUID {
    public init(cfUUID: CFUUID) {
        self = withUnsafePointer(to: CFUUIDGetUUIDBytes(cfUUID)) { buf in
            buf.withMemoryRebound(to: uuid_t.self, capacity: 1) { raw in
                UUID(uuid: raw.pointee)
            }
        }
    }
}

public struct Display: Hashable {
    public enum Error: Swift.Error {
        case invalidDisplay
        case invalidMainDisplay
        case switchingToSameSpace
    }

    public static var main: Display { .init(raw: CGMainDisplayID()) }

    public let raw: CGDirectDisplayID
    public init(raw: CGDirectDisplayID) {
        self.raw = raw
    }

    private static func fetchDisplays(
        _ fetch: (CGDisplayCount, UnsafeMutablePointer<CGDirectDisplayID>?, UnsafeMutablePointer<CGDisplayCount>) -> CGDisplayErr
    ) throws -> [Display] {
        var count: CGDisplayCount = 0
        try GraphicsConnection.check(fetch(0, nil, &count))
        guard count != 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: kCGNullDirectDisplay, count: Int(count))
        var fetched: CGDisplayCount = 0
        try GraphicsConnection.check(fetch(count, &ids, &fetched))
        return ids.prefix(Int(min(fetched, count))).map(Display.init(raw:))
    }

    public static func allActive() throws -> [Display] {
        try fetchDisplays(CGSGetActiveDisplayList)
    }

    public static func allOnline() throws -> [Display] {
        try fetchDisplays(CGSGetOnlineDisplayList)
    }

    public func currentSpace(for connection: GraphicsConnection = .main) throws -> Space {
        let space = try CGSManagedDisplayGetCurrentSpace(connection.raw, uuid() as CFString)
        return try Space(raw: space).orThrow(Space.Error.invalid)
    }

    /// One record of `CGSCopyManagedDisplaySpaces`: the Mission Control Spaces of one display.
    public struct ManagedSpaces: Equatable {
        /// The display's UUID string, or `"Main"` for the single shared record when
        /// "Displays have separate Spaces" is off.
        public let displayIdentifier: String
        public let currentSpace: CGSSpaceID?
        public let spaces: [CGSSpaceID]

        init?(record: [String: Any]) {
            guard let identifier = record["Display Identifier"] as? String else { return nil }
            displayIdentifier = identifier
            currentSpace = (record["Current Space"] as? [String: Any]).flatMap(Self.spaceID)
            spaces = (record["Spaces"] as? [[String: Any]] ?? []).compactMap(Self.spaceID)
        }

        private static func spaceID(_ values: [String: Any]) -> CGSSpaceID? {
            let id = (values["ManagedSpaceID"] as? NSNumber)?.uint64Value ?? (values["id64"] as? NSNumber)?.uint64Value
            return id == 0 ? nil : id
        }
    }

    /// The managed (Mission Control) Space topology of every display.
    public static func managedSpaces(for connection: GraphicsConnection = .main) throws -> [ManagedSpaces] {
        guard let records = CGSCopyManagedDisplaySpaces(connection.raw)?.takeRetainedValue() as? [[String: Any]] else {
            throw Space.Error.listFailed
        }
        return records.compactMap(ManagedSpaces.init(record:))
    }

    public func uuid() throws -> String {
        if self == .main {
            // this isn't actually a UUID (it's "Main") so we can't return
            // an [NS]UUID
            return try kCGSPackagesMainDisplayIdentifier
                .flatMap { $0.takeUnretainedValue() as String? }
                .orThrow(Error.invalidMainDisplay)
        }
        let uuid = try CGDisplayCreateUUIDFromDisplayID(raw).orThrow(Error.invalidDisplay).takeRetainedValue()
        return UUID(cfUUID: uuid).uuidString
    }
}
