# BetterSwiftAX

Modern Swift wrapper around macOS's Accessibility (AX) APIs — typed attributes, thrown errors, automatic `AXValue` conversion, one-line observers — plus a window/Space control layer built on private CGS/SkyLight APIs.

Originally created for Texts.com iMessage integration and published after `git filter-repo`.

```swift
import AccessibilityControl

guard Accessibility.isTrusted(shouldPrompt: true) else { fatalError("grant AX permission") }

let app = Accessibility.Element(pid: someApp.processIdentifier)
let window = try app.appFocusedWindow()           // Accessibility.Element
let title: String = try window.title()            // typed — no casts, no AXError checks
try window.position(assign: CGPoint(x: 0, y: 0))  // AXValue boxing handled for you
try window.windowCloseButton().press()            // actions read like methods

let token = try app.observe(.focusedWindowChanged) { info in
    print("focus changed:", info["AXUIElement"] as Any)
}   // retain the token; that's the whole observer lifecycle
```

## What it gives you over raw HIServices

- **Thrown, located errors** — every `AXError` becomes an `AccessibilityError` with the call site's file/line; no `guard err == .success` chains.
- **Typed attributes** — `Attribute<String>`, `MutableAttribute<CGPoint>`, `ParameterizedAttribute<Range<Int>, String>`: value types and read/write capability are checked at compile time.
- **Automatic conversion** — `CGPoint`/`CGSize`/`CGRect`/`Range<Int>`, elements, arrays, and dictionaries cross the `AXValue`/`CFTypeRef` boundary transparently.
- **Ergonomic access** — `@dynamicMemberLookup` + `callAsFunction`: `try element.title()`, `try element.press()`, extendable with your own attribute names.
- **One-line observers** — the `AXObserver`/run-loop/C-callback ceremony collapses into `element.observe(...) { }` returning a cancellation token (Combine supported).
- **Traversal & inspection tools** — bounded recursive tree walking, XML dumps of UI state (with PII stripping), and single-round-trip bulk hierarchy snapshots via the private `AXUIElementCopyHierarchy`.
- **Window/Space control** (`WindowControl`) — window enumeration, per-window alpha, Space listing/creation, moving windows between Spaces, display↔Space mapping via private CGS APIs.

## Documentation

| | |
|---|---|
| **[Guide](docs/guide.md)** | The mental model, raw-API→wrapper mapping table, building blocks, extension points, escape hatches, and sharp edges. Start here. |
| **[Recipes](docs/recipes.md)** | Bite-sized, copy-paste examples for common tasks. |
| **[WindowControl](docs/window-control.md)** | The CGS/private-API layer: `Window`, `Space`, `Display`, `Dock`. |

The repo also contains **BetterAccessibilityInspector**, a SwiftUI accessibility-tree inspector built on this package — a good reference consumer.

## Installation

In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/TextsHQ/BetterSwiftAX", branch: "main"),
]
```

Then `import AccessibilityControl` (and `import WindowControl` if needed).

Your process must be granted accessibility access (System Settings → Privacy & Security → Accessibility); check with `Accessibility.isTrusted(shouldPrompt:)`. Parts of the package use private APIs and are not App Store-safe — see the [guide](docs/guide.md#sharp-edges).

## Related

* [AXSwift](https://github.com/tmandry/AXSwift)
