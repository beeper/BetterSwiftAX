import Foundation
import CoreGraphics
import CWindowControl

/// SkyLight's bridged window-management operations (`SLSWindowManagementFallbackBridge`),
/// resolved at runtime rather than linked.
///
/// Apart from Space creation, operations are enqueued asynchronously: `true` means
/// SkyLight accepted the operation, not that it has been applied. Read the result
/// back with ``Space/ids(forWindow:)`` or ``Space/list(_:for:)``.
public final class SpaceBridge {
    private let raw: NSObject

    /// Returns `nil` if SkyLight or the bridge class is unavailable on this system.
    public init?() {
        guard let raw = TXTSpaceBridgeCreate() else { return nil }
        self.raw = raw
    }

    /// Creates a Space from a raw values dictionary (e.g. `["type": 0, "uuid": ...]`).
    public func createSpace(values: [String: Any]) -> UInt64? {
        let id = TXTSpaceBridgeCreateSpace(raw, values)
        return id == 0 ? nil : id
    }

    /// Creates an intrinsically unknown, unmanaged Space (creation option 1) with no Dock owner metadata.
    /// A `type: 3` dictionary passed to ``createSpace(values:)`` still creates a managed user Space.
    public func createUnknownSpace(uuid: String) -> UInt64? {
        let id = TXTSpaceBridgeCreateUnknownSpace(raw, uuid)
        return id == 0 ? nil : id
    }

    /// Adds membership in an unknown Space. Existing memberships are kept; remove them separately.
    public func addWindow(_ window: CGWindowID, toUnknownSpace space: UInt64) -> Bool {
        TXTSpaceBridgeAddWindowToUnknownSpace(raw, window, space)
    }

    public func removeWindow(_ window: CGWindowID, fromSpaces spaces: [UInt64]) -> Bool {
        TXTSpaceBridgeRemoveWindowFromSpaces(raw, window, spaces.map { NSNumber(value: $0) })
    }

    /// Moves a window to a managed Space.
    public func moveWindow(_ window: CGWindowID, toSpace space: UInt64) -> Bool {
        TXTSpaceBridgeMoveWindow(raw, window, space)
    }

    public func destroySpace(_ space: UInt64) -> Bool {
        TXTSpaceBridgeDestroySpace(raw, space)
    }
}

// MARK: - Runtime-resolved Space reads

extension Space {
    /// IDs of every Space containing `window`, including unknown/OS Spaces (mask 15).
    /// `nil` if the SkyLight symbols are unavailable.
    public static func ids(forWindow window: CGWindowID) -> [UInt64]? {
        TXTSpacesForWindow(window)?.map(\.uint64Value)
    }

    /// The active Space's ID, or `nil` if it could not be read.
    public static func activeID() -> UInt64? {
        let id = TXTActiveSpace()
        return id == 0 ? nil : id
    }

    /// Raw `SLSCopyManagedDisplaySpaces` records (`"Display Identifier"`, `"Current Space"`, `"Spaces"`, ...).
    public static func managedDisplaySpaces() -> [[String: Any]]? {
        TXTCopyManagedDisplaySpaces() as? [[String: Any]]
    }

    /// The intrinsic `CGSSpaceType` raw value of a Space (0 user, 3 unknown, ...), or `nil`
    /// if the binding or WindowServer connection is unavailable.
    public static func rawType(of space: UInt64) -> Int32? {
        let type = TXTSpaceType(space)
        return type < 0 ? nil : type
    }

    /// A Space's metadata, read independently of its type. `nil` means the read failed.
    public static func values(of space: UInt64) -> [String: Any]? {
        TXTCopySpaceValues(space) as? [String: Any]
    }
}
