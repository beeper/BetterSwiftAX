# WindowControl

`WindowControl` is the second module in this package, and it is **not an accessibility API**. It wraps CoreGraphics window services plus a set of **private CGS/SkyLight symbols** (declared in the `CWindowControl` C shim) for things the public API can't do at all: enumerating and manipulating Spaces, moving windows between Spaces, per-window alpha, display↔Space mapping.

```swift
import WindowControl
```

> **Warning.** Private APIs come with the usual caveats: they can change or silently stop working between macOS releases (see [status on macOS 27.2.1](#status-on-macos-2721)), and they are not App Store-safe. Errors surface as `GraphicsConnection.Error` wrapping a `CGError` with file/line, mirroring `AccessibilityError` on the AX side.

## `CGS*` and `SLS*` are the same functions

The window server's client library is the private SkyLight framework, whose functions are named `SLS*`. CoreGraphics re-exports many of them under the older `CGS*` names, so each one is a single function with two names. Linking `CGSFoo` binds to SkyLight's `SLSFoo`, and calling it through `dlsym("SLSFoo")` runs exactly the same code. You can check any symbol with:

```sh
dyld_info -exports /System/Library/Frameworks/CoreGraphics.framework/CoreGraphics | grep _CGSCopySpacesForWindows
#   [re-export] _CGSCopySpacesForWindows (_SLSCopySpacesForWindows from SkyLight)
```

On macOS 27.2.1, all 31 `CGS*` functions this package calls are re-exports like this, `CGSMainConnectionID` included. That doesn't hold for every `CGS*` symbol: CoreGraphics still implements about 120 of its own. So when a `CGS*` call stops working, switching to its `SLS*` name won't help. What helps is a different API, such as the `SpaceBridge` operations below.

## Status on macOS 27.2.1

Checked against live WindowServer state on macOS 27.2.1. "Own window" is a window of the calling process; "other window" is one owned by another process (for example Messages).

| API | Own window | Other window | Use instead |
|---|---|---|---|
| `Space.list`, `Space.active()`, `kind()`, `values()`, `Window.currentSpaces`, `Display.managedSpaces()` | Works | Works | |
| `Window.move(from:to:)`: `CGSAddWindowsToSpaces` / `CGSRemoveWindowsFromSpaces` | Works | **No-op** | `SpaceBridge.add(_:toUnknownSpace:)`, `remove(_:from:)` |
| `Window.moveToSpace` to a managed Space: `CGSMoveWindowsToManagedSpace` | Works | **No-op** | `SpaceBridge.move(_:toManagedSpace:)` |
| `Space(newSpaceOfKind: .user)`: `CGSSpaceCreate` | **Fails** (returns 0; the initializer throws) | n/a | `SpaceBridge.createSpace(values:)` |
| `Space(newSpaceOfKind: .unknown)`: `CGSSpaceCreate` option 1 | Works | n/a | `SpaceBridge.createUnknownSpace(uuid:)` for one with no Dock owner |
| `SpaceBridge` create / add / remove / move / destroy | Works | Works | |

The no-ops fail silently: the call returns and Space membership doesn't change. Older notes in the source date the membership no-ops to macOS 12.2.

## The bridge from AccessibilityControl

AX elements and CG windows are different worlds with different identifiers. The bridge is:

```swift
let window: Window = try axWindowElement.window()   // private _AXUIElementGetWindow
```

which takes an `Accessibility.Element` of role `AXWindow` to a `Window` (a `CGWindowID`). There is no general reverse mapping.

## `GraphicsConnection`

A handle to the window server connection (`CGSConnectionID`). Every call in this module takes a connection and defaults to `GraphicsConnection.main`, so you can usually ignore it. `connection(for: pid)` fetches another process's connection when you need to operate on its behalf.

## `Window`

A value type wrapping a `CGWindowID`.

```swift
// enumerate windows
let all = try Window.list(.onScreen, excludeDesktopElements: true)

// enumerate with metadata (CGWindowListCopyWindowInfo, malformed entries skipped)
for desc in try Window.listDescriptions(.onScreen) {
    print(desc.window.raw, desc.ownerName ?? "?", desc.bounds, desc.layer)
}

// metadata for one window
let desc = try someWindow.describe()
```

`ListOptions` covers the CG window-list modes: `.all`, `.onScreen`, `.onScreenAbove(window, orEqual:)`, `.onScreenBelow(window, orEqual:)`. A `Description` exposes name, bounds, layer, alpha, owner pid/name, sharing state, backing store, and memory usage.

Space-related operations (all private API):

```swift
let spaces = try window.currentSpaces()          // Spaces this window is on; pass .allOSSpaces to include unknown Spaces
try window.moveToSpace(targetSpace)             // own windows only on macOS 27.2.1; see SpaceBridge for others
try window.setAlpha(0.5)                        // may only work for your own windows
```

## `Space`

Wraps a `CGSSpaceID` (Mission Control desktops, fullscreen spaces, etc. — entirely private API).

```swift
let current = try Space.active()
let all = try Space.list(.allSpaces)

print(current.kind())          // .user / .fullscreen / .system / .tiled / .unknown / .other(raw)
print(try current.name())
print(try current.owners())    // pids
```

`ListOptions` presets: `.currentSpaces`, `.otherSpaces`, `.allSpaces`, `.allOSSpaces`, `.allVisibleSpaces`.

You can also *create* spaces:

```swift
let space = try Space(newSpaceOfKind: .user)   // destroyWhenDone: true by default; throws on macOS 27.2.1, use SpaceBridge
```

Notes:

- A `Space` created with `newSpaceOfKind:` is destroyed in `deinit` unless `destroyWhenDone: false` — keep it alive as long as you need it.
- `show()` / `hide()` toggle space visibility and are easy to misuse; prefer moving the window instead.
- Moving windows to spaces of kind `.unknown` uses a different code path than managed spaces; `moveToSpace` picks the right one automatically, but both paths only move the caller's own windows on macOS 27.2.1.
- `level`, `values`/`setValues`, and `compatID` expose lower-level CGS state for advanced use.
- `kind()` reports `.unknown` for an ID that no longer exists. Check `Space.exists(_:)` before trusting it.
- `Space.raw` is the 64-bit SkyLight ID (`CGSSpaceID` is `uint64_t`), so it can be stored and compared directly.

### `SpaceBridge`

`SpaceBridge` drives SkyLight's `SLSWindowManagementFallbackBridge` (resolved with `NSClassFromString`; the classes are Objective-C only, so they cannot be linked). It is the only way here to move another process's window between Spaces on macOS 27.2.1 (the CGS membership calls behind `Window.moveToSpace` are no-ops there), and to create an intrinsically unknown, unmanaged Space with no Dock owner, which `Space(newSpaceOfKind: .unknown)` cannot:

```swift
guard let bridge = SpaceBridge() else { return }
let parking = try bridge.createUnknownSpace(uuid: "MyApp-Parking")  // not destroyed automatically
try bridge.add(window, toUnknownSpace: parking)
// Adding keeps old memberships: wait until it shows up, then remove the rest.
let others = try window.currentSpaces(.allOSSpaces).filter { $0 != parking }
try bridge.remove(window, from: others)
```

Everything except creation is enqueued asynchronously: returning means accepted, not applied, so poll `window.currentSpaces(.allOSSpaces)` (`.allSpaces` omits unknown Spaces) until it matches. When finished, `try bridge.destroy(parking)`.

## `Display`

Wraps a `CGDirectDisplayID`.

```swift
let displays = try Display.allActive()          // or allOnline()
let space = try Display.main.currentSpace()     // active Space on that display
let id = try Display.main.uuid()                // note: "Main" for the main display, not a real UUID

for record in try Display.managedSpaces() {     // Mission Control topology, one record per display
    print(record.displayIdentifier, record.currentSpace as Any, record.spaces)
}
```

## `Process` and `Dock`

Small utilities used by the Space machinery, useful on their own:

```swift
try Process.monitorExit(pid: somePid) { print("exited") }   // dispatch-source based
let hung = try Process.isUnresponsive(somePid)              // window-server's view of "not responding"

Dock.pid                                    // pid of com.apple.dock, if running
let observer = Dock.Observer(onExit: { … }) // fires when the Dock restarts (retain it)
```

The Dock matters here because user-space visibility and managed-space moves involve the Dock process; `Dock.Observer` lets you re-apply Space state after the Dock restarts (which destroys/recreates Space state).
