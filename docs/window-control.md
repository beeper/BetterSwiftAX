# WindowControl

`WindowControl` is the second module in this package, and it is **not an accessibility API**. It wraps CoreGraphics window services plus a set of **private CGS/SkyLight symbols** (declared in the `CWindowControl` C shim) for things the public API can't do at all: enumerating and manipulating Spaces, moving windows between Spaces, per-window alpha, display↔Space mapping.

```swift
import WindowControl
```

> **Warning.** Private APIs come with the usual caveats: they can change or silently stop working between macOS releases (e.g. `CGSAddWindowsToSpaces`/`CGSRemoveWindowsFromSpaces` became no-ops in macOS 12.2 — the code works around this), and they are not App Store-safe. Errors surface as `GraphicsConnection.Error` wrapping a `CGError` with file/line, mirroring `AccessibilityError` on the AX side.

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
let spaces = try window.currentSpaces()          // Spaces this window is on
try window.moveToSpace(targetSpace)             // handles managed vs. unmanaged spaces
try window.setAlpha(0.5)                        // may only work for your own windows
```

## `Space`

Wraps a `CGSSpaceID` (Mission Control desktops, fullscreen spaces, etc. — entirely private API).

```swift
let current = try Space.active()
let all = try Space.list(.allSpaces)

print(try current.kind())      // .user / .fullscreen / .system / .tiled / .unknown
print(try current.name())
print(try current.owners())    // pids
```

`ListOptions` presets: `.currentSpaces`, `.otherSpaces`, `.allSpaces`, `.allOSSpaces`, `.allVisibleSpaces`.

You can also *create* spaces:

```swift
let space = Space(newSpaceOfKind: .user)   // destroyWhenDone: true by default
```

Notes:

- A `Space` created with `newSpaceOfKind:` is destroyed in `deinit` unless `destroyWhenDone: false` — keep it alive as long as you need it.
- `show()` / `hide()` toggle space visibility and are easy to misuse; prefer `Window.moveToSpace` for the common case.
- Moving windows to spaces of kind `.unknown` uses a different code path than managed spaces; `moveToSpace` picks the right one automatically.
- `level`, `values`/`setValues`, and `compatID` expose lower-level CGS state for advanced use.

## `Display`

Wraps a `CGDirectDisplayID`.

```swift
let displays = try Display.allActive()          // or allOnline()
let space = try Display.main.currentSpace()     // active Space on that display
let id = try Display.main.uuid()                // note: "Main" for the main display, not a real UUID
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
