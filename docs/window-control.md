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

On macOS 27.2.1 every `CGS*` function this package calls is such a re-export, so when one stops working, switching to its `SLS*` name won't help. Use the [bridge-backed operations](#writing-space-state) instead.

## Status on macOS 27.2.1

"Own window" belongs to the calling process; "other window" to another process (for example Messages).

| API | Own window | Other window | Use instead |
|---|---|---|---|
| `Space.list`, `Space.active()`, `kind()`, `values()`, `Window.currentSpaces`, `Display.managedSpaces()` | Works | Works | |
| `Window.move(from:to:)`: `CGSAddWindowsToSpaces` / `CGSRemoveWindowsFromSpaces` | Works | **No-op** | `Window.add(toUnknownSpace:)`, `remove(from:)` |
| `Window.moveToSpace` to a managed Space: `CGSMoveWindowsToManagedSpace` | Works | **No-op** | `Window.move(toManagedSpace:)` |
| `Space(newSpaceOfKind: .user)`: `CGSSpaceCreate` | **Fails** (returns 0; the initializer throws) | n/a | `Space.create(values:)` |
| `Space(newSpaceOfKind: .unknown)`: `CGSSpaceCreate` option 1 | Works | n/a | `Space.createUnknown(uuid:)` for one with no Dock owner |

The no-ops fail silently. The replacements work on both kinds of window.

## From AccessibilityControl

```swift
let window: Window = try axWindowElement.window()   // private _AXUIElementGetWindow
```

This takes an `AXWindow` element to its `Window`. There is no reverse mapping.

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
try window.moveToSpace(targetSpace)             // CGS: own windows only on macOS 27.2.1
try window.setAlpha(0.5)                        // may only work for your own windows
```

## `Space`

Wraps a `CGSSpaceID` (Mission Control desktops, fullscreen Spaces, etc.).

```swift
let current = try Space.active()
let all = try Space.list(.allSpaces)

print(current.kind())          // .user / .fullscreen / .system / .tiled / .unknown / .other(raw)
print(try current.name())
print(try current.owners())    // pids
```

`ListOptions` presets: `.currentSpaces`, `.otherSpaces`, `.allSpaces`, `.allOSSpaces`, `.allVisibleSpaces`.

Notes:

- `Space(newSpaceOfKind:)` creates through CGS and destroys the Space in `deinit` unless `destroyWhenDone: false`. Prefer `Space.create`/`createUnknown` below.
- `show()` / `hide()` toggle space visibility and are easy to misuse; prefer moving the window instead.
- `kind()` reports `.unknown` for an ID that no longer exists. Check `Space.exists(_:)` before trusting it.

### Writing Space state

These go through SkyLight's `SLSWindowManagementFallbackBridge` when `Space.isBridgeAvailable`, and fall back to CGS otherwise:

```swift
let parking = try Space.createUnknown(uuid: "MyApp-Parking") // unmanaged, no Dock owner; not destroyed automatically
try window.add(toUnknownSpace: parking)
// Adding keeps old memberships: wait until it shows up, then remove the rest.
let others = try window.currentSpaces(.allOSSpaces).filter { $0 != parking }
try window.remove(from: others)
// later
try window.move(toManagedSpace: desktop)
try parking.destroy()
```

Everything except creation is asynchronous through the bridge: returning means accepted, not applied. Poll `window.currentSpaces(.allOSSpaces)` (`.allSpaces` omits unknown Spaces) or `Space.exists(_:)`.

`destroy()` asks both the bridge and CGS, since each only destroys Spaces it created.

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

Small utilities used by the Space machinery:

```swift
try Process.monitorExit(pid: somePid) { print("exited") }   // dispatch-source based
let hung = try Process.isUnresponsive(somePid)              // window-server's view of "not responding"

Dock.pid                                    // pid of com.apple.dock, if running
let observer = Dock.Observer(onExit: { … }) // fires when the Dock restarts (retain it)
```

A Dock restart recreates Space state, so use `Dock.Observer` to re-apply yours.
