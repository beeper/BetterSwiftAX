import Foundation
import CoreGraphics
import CWindowControl

/// SkyLight's bridged window-management operations (`SLSWindowManagementFallbackBridge`),
/// resolved at runtime with `NSClassFromString`.
///
/// Use this instead of ``Window/moveToSpace(_:for:)`` to move another process's window: the CGS
/// membership calls behind it are no-ops for other processes' windows on macOS 27.2.1. It also
/// creates Spaces where `CGSSpaceCreate` fails, including an intrinsically unknown Space with no
/// Dock owner.
///
/// Apart from creation, operations are enqueued asynchronously: returning without throwing
/// means SkyLight accepted the operation, not that it has been applied. Read the result back
/// with ``Window/currentSpaces(_:for:)`` (pass `.allOSSpaces` to see unknown Spaces).
///
/// Spaces created here are not destroyed automatically; call ``destroy(_:)``.
public final class SpaceBridge {
    public struct Error: Swift.Error, CustomStringConvertible {
        public let operation: String
        public var description: String { "SkyLight bridge rejected \(operation)" }
    }

    private let raw: NSObject

    /// Returns `nil` if SkyLight or the bridge class is unavailable on this system.
    public init?() {
        guard let raw = TXTSpaceBridgeCreate() else { return nil }
        self.raw = raw
    }

    /// Creates a Space from a raw values dictionary (e.g. `["type": 0, "uuid": ...]`).
    public func createSpace(values: [String: Any]) throws -> Space {
        try Space(raw: TXTSpaceBridgeCreateSpace(raw, values)).orThrow(Error(operation: "Space creation"))
    }

    /// Creates an intrinsically unknown, unmanaged Space (creation option 1) with no Dock owner
    /// metadata. A `type: 3` dictionary passed to ``createSpace(values:)`` still creates a
    /// managed user Space.
    public func createUnknownSpace(uuid: String) throws -> Space {
        try Space(raw: TXTSpaceBridgeCreateUnknownSpace(raw, uuid)).orThrow(Error(operation: "unknown Space creation"))
    }

    /// Adds membership in an unknown Space. Existing memberships are kept; ``remove(_:from:)`` them
    /// once the new one is visible.
    public func add(_ window: Window, toUnknownSpace space: Space) throws {
        try check(TXTSpaceBridgeAddWindowToUnknownSpace(raw, window.raw, space.raw), "unknown Space membership")
    }

    public func remove(_ window: Window, from spaces: [Space]) throws {
        let ids = spaces.map { NSNumber(value: $0.raw) }
        try check(TXTSpaceBridgeRemoveWindowFromSpaces(raw, window.raw, ids), "Space membership removal")
    }

    /// Moves a window to a managed Space.
    public func move(_ window: Window, toManagedSpace space: Space) throws {
        try check(TXTSpaceBridgeMoveWindow(raw, window.raw, space.raw), "managed Space move")
    }

    public func destroy(_ space: Space) throws {
        try check(TXTSpaceBridgeDestroySpace(raw, space.raw), "Space destruction")
    }

    private func check(_ accepted: Bool, _ operation: String) throws {
        guard accepted else { throw Error(operation: operation) }
    }
}
