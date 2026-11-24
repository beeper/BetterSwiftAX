import Foundation
import CoreGraphics
import CWindowControl

/// SkyLight's `SLSWindowManagementFallbackBridge`, resolved once with `NSClassFromString`.
/// The Space and Window write operations below use it when it exists and fall back to the
/// CGS calls otherwise.
enum SpaceBridge {
    static let shared: NSObject? = TXTSpaceBridgeCreate()

    static func check(_ accepted: Bool, _ operation: String) throws {
        guard accepted else { throw Space.Error.rejected(operation: operation) }
    }
}

extension Space {
    /// Whether SkyLight's window-management bridge is available. When it is, the Space and
    /// Window write operations (``create(values:)``, ``createUnknown(uuid:)``, ``destroy(for:)``,
    /// ``Window/add(toUnknownSpace:)``, ``Window/remove(from:)``, ``Window/move(toManagedSpace:)``)
    /// go through it and work on other processes' windows. Without it they fall back to the CGS
    /// calls, which on macOS 27.2.1 only move the caller's own windows.
    public static var isBridgeAvailable: Bool { SpaceBridge.shared != nil }

    /// Creates a Space from a raw values dictionary (e.g. `["type": 0, "uuid": ...]`). A `type: 3`
    /// dictionary still creates a managed user Space; use ``createUnknown(uuid:)`` for an unknown one.
    /// Unlike ``init(newSpaceOfKind:destroyWhenDone:display:connection:)``, the Space is not
    /// destroyed automatically.
    public static func create(values: [String: Any]) throws -> Space {
        let raw = SpaceBridge.shared.map { TXTSpaceBridgeCreateSpace($0, values) }
            ?? CGSSpaceCreate(GraphicsConnection.main.raw, nil, values as CFDictionary)
        return try Space(raw: raw).orThrow(Error.rejected(operation: "Space creation"))
    }

    /// Creates an intrinsically unknown, unmanaged Space (creation option 1). Through the bridge it
    /// has no Dock owner metadata. Not destroyed automatically.
    public static func createUnknown(uuid: String) throws -> Space {
        let raw = SpaceBridge.shared.map { TXTSpaceBridgeCreateUnknownSpace($0, uuid) }
            ?? CGSSpaceCreate(GraphicsConnection.main.raw, UnsafeMutableRawPointer(bitPattern: 1),
                              ["uuid": uuid, "type": CGSSpaceTypeUnknown.rawValue] as CFDictionary)
        return try Space(raw: raw).orThrow(Error.rejected(operation: "unknown Space creation"))
    }
}

extension Window {
    /// Adds membership in an unknown Space. Existing memberships are kept; ``remove(from:)`` them
    /// once the new one shows up in ``currentSpaces(_:for:)`` with `.allOSSpaces`.
    public func add(toUnknownSpace space: Space) throws {
        guard let bridge = SpaceBridge.shared else {
            return CGSAddWindowsToSpaces(GraphicsConnection.main.raw, [raw] as CFArray, [space.raw] as CFArray)
        }
        try SpaceBridge.check(TXTSpaceBridgeAddWindowToUnknownSpace(bridge, raw, space.raw), "unknown Space membership")
    }

    public func remove(from spaces: [Space]) throws {
        guard let bridge = SpaceBridge.shared else {
            return CGSRemoveWindowsFromSpaces(GraphicsConnection.main.raw, [raw] as CFArray, spaces.map(\.raw) as CFArray)
        }
        let ids = spaces.map { NSNumber(value: $0.raw) }
        try SpaceBridge.check(TXTSpaceBridgeRemoveWindowFromSpaces(bridge, raw, ids), "Space membership removal")
    }

    /// Moves the window to a managed (user or fullscreen) Space.
    public func move(toManagedSpace space: Space) throws {
        guard let bridge = SpaceBridge.shared else {
            return CGSMoveWindowsToManagedSpace(GraphicsConnection.main.raw, [raw] as CFArray, space.raw)
        }
        try SpaceBridge.check(TXTSpaceBridgeMoveWindow(bridge, raw, space.raw), "managed Space move")
    }
}
