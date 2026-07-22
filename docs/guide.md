# BetterSwiftAX Guide

This is the core guide to `AccessibilityControl`, the main module of BetterSwiftAX. It assumes you already know roughly what the macOS Accessibility (AX) API does — `AXUIElement`, attributes, actions, observers — and explains how this framework maps onto it, what boilerplate it removes, and where its edges are.

For copy-paste examples, see [recipes.md](recipes.md). For the window/Space/display layer (a separate substrate built on CoreGraphics private APIs, not AX), see [window-control.md](window-control.md).

## The mental model

Four ideas carry the whole framework:

1. **An `Accessibility.Element` is a remote handle.** It wraps an `AXUIElement`, which refers to a UI object living *in another process*. Every attribute read, action, or hit test is an IPC round-trip into that process, and any of them can fail at any time (the app quit, the element disappeared, the app is hung). That is why essentially everything in this API `throws`.

2. **Accessing a member builds an accessor; *calling* it performs the IPC.** `element.title` doesn't fetch anything — via `@dynamicMemberLookup` it constructs a typed `Attribute<String>` bound to that element. Invoking it like a function (`try element.title()`) is what actually talks to the target process. The same split applies to actions (`element.press` builds an `Action`, `try element.press()` performs it) and mutable attributes (`try element.position(assign: point)`).

3. **`Accessibility.Names` is the vocabulary — and the main extension point.** The dynamic member lookup on `Element` resolves through `Accessibility.Names`, a namespace of typed name definitions (`title` → `Attribute<String>.Name`, `position` → `MutableAttribute<CGPoint>.Name`, `press` → `Action.Name`, …). To teach the framework a new attribute — including private, app-specific ones — you extend `Names`. See [Extending the vocabulary](#extending-the-vocabulary).

4. **Conversion is automatic at the boundary.** The `AccessibilityConvertible` protocol transparently boxes/unboxes `AXValue` structs (`CGPoint`, `CGSize`, `CGRect`, `Range<Int>`), `Element`s, and arrays/dictionaries thereof. You never call `AXValueCreate`/`AXValueGetValue` or cast `CFTypeRef`s yourself.

## Mapping from the raw API

If you already know HIServices, this table is most of the learning curve:

| Raw HIServices pattern | BetterSwiftAX |
|---|---|
| `AXIsProcessTrustedWithOptions(...)` | `Accessibility.isTrusted(shouldPrompt:)` |
| `AXUIElementCreateApplication(pid)` | `Accessibility.Element(pid:)` |
| `AXUIElementCreateSystemWide()` | `Accessibility.Element.systemWide` |
| `AXUIElementCopyAttributeValue` + `AXError` check + `CFTypeRef` cast | `let title: String = try element.title()` |
| `AXValueCreate(.cgPoint, &p)` + `AXUIElementSetAttributeValue` | `try element.position(assign: point)` |
| `AXUIElementIsAttributeSettable` | `try element.position.isSettable()` |
| `AXUIElementCopyAttributeNames` | `try element.supportedAttributes()` |
| `AXUIElementGetAttributeValueCount` | `try element.children.count()` |
| `AXUIElementCopyAttributeValues(el, attr, index, count, &out)` | `try element.children(range: 0..<10)` or `try element.children[3]` |
| `AXUIElementCopyParameterizedAttributeValue` | `try element.parameterizedAttribute(name)(param)` |
| `AXUIElementPerformAction(el, kAXPressAction)` | `try element.press()` |
| `AXUIElementCopyActionNames` | `try element.supportedActions()` |
| `AXUIElementCopyElementAtPosition` | `try element.hitTest(at: point)` |
| `AXUIElementGetPid` | `try element.pid()` |
| `AXUIElementSetMessagingTimeout` | `try element.setMessagingTimeout(5)` |
| `AXObserverCreateWithInfoCallback` + run-loop source + context pointer | `let token = try element.observe(.focusedWindowChanged) { info in … }` |
| `_AXUIElementGetWindow` (private) | `try element.window()` → `WindowControl.Window` |
| `AXUIElementCopyHierarchy` (private, via `dlsym`) | `try element.copyHierarchy(requesting:options:)` |

## Building blocks

### `Accessibility.Element`

The wrapper around `AXUIElement`. Create one from a pid (`Element(pid:)`), from the system-wide element (`Element.systemWide`), from a raw `AXUIElement` (`Element(raw:)`), or from an untyped `CFTypeRef` you got out of some other API (`Element(erased:)`, failable). `NSRunningApplication` also has a convenience: `app._accessibilityElement`.

Elements are `Equatable` via `CFEqual`. The underlying `raw: AXUIElement` is always public — see [Escape hatches](#escape-hatches-when-to-go-raw).

### Attributes: `Attribute<Value>`, `MutableAttribute<Value>`, `ParameterizedAttribute<Parameter, Return>`

All three are *bound accessors*: an `(element, name)` pair where the name is a phantom-typed string (`Attribute<String>.Name` is just a `String` at runtime, but carries the value type at compile time). What the phantom types buy you:

- `try element.title()` returns `String` — no cast, no `CFTypeRef`.
- Read/write capability is in the type system: `title` is an `Attribute` (read-only), `position` is a `MutableAttribute` (readable *and* assignable via `try element.position(assign: p)`). You cannot accidentally write to a read-only attribute.
- Parameterized attributes type both sides: a `ParameterizedAttribute<Range<Int>, String>` is called as `try attr(0..<100)` and returns `String`.

Attributes whose value is a collection get three extras (backed by the more efficient ranged AX calls): `count()`, `callAsFunction(range:)`, and a throwing `subscript` — e.g. `try app.appWindows.count()` without fetching the array.

### Actions: `Action`

Same shape: `element.press` builds an `Action`, `try element.press()` performs it. `element.supportedActions()` enumerates what the element offers; an `Action`'s `description` is the human-readable description supplied by the target app. `Action.Name` also has static members for every standard action (`.press`, `.confirm`, `.showMenu`, …) usable with `element.action(.press)`.

### Observers: `Observer` and `Token`

`try element.observe(.windowMoved) { info in … }` wraps the whole `AXObserver` ceremony: creating the observer for the element's pid, installing its run-loop source, and bridging the C callback. It returns a `Token`; there is also a Combine flavor, `element.publisher(for:)`, returning `AnyCancellable`.

Two rules, both about lifetime:

- **You must retain the token.** Dropping it cancels the subscription (`deinit` calls `cancel()`).
- **The chosen run loop must actually be running.** The default is `RunLoop.current` — on the main thread that's fine; on an arbitrary background thread/queue, nothing will ever fire.

The `info` dictionary passed to your callback contains whatever the notification supplies, plus the triggering element under the key `"AXUIElement"` (as an `Accessibility.Element`).

Notification names are the same phantom-name pattern: `Accessibility.Notification` has static members for all standard notifications (`.focusedWindowChanged`, `.windowCreated`, `.valueChanged`, …), and `NSAccessibility.Notification` is accepted interchangeably.

### Errors: `AccessibilityError`

Every non-`.success` `AXError` becomes a thrown `AccessibilityError` carrying the code plus the `#fileID`/`#line` of the call site — so an error printed from deep inside a traversal still tells you which call produced it. Codes worth knowing when debugging:

- `.noValue` — the attribute exists but has no value right now (e.g. no focused window).
- `.attributeUnsupported` / `.actionUnsupported` — the element doesn't implement it at all.
- `.cannotComplete` — usually the target app is hung, dead, or not responding to AX; consider `setMessagingTimeout`.
- `.apiDisabled` — your process isn't trusted (see `Accessibility.isTrusted`).
- `.failure` on an attribute *read* that you'd expect to succeed often means a **type mismatch**: the value arrived but couldn't convert to the `Value` type you declared. Re-declare as `Attribute<Any>` and inspect what actually comes back.

### Two vocabularies: `Names` vs. the generated constants

The framework ships two parallel sets of name definitions; knowing which to reach for avoids confusion:

- **`Accessibility.Names`** (`Names+Standard.swift`) — the curated, *typed* vocabulary that powers dynamic member lookup. Hand-maintained, covers the commonly used attributes/actions.
- **Generated plain-string constants** — `Accessibility.AttributeKey`, `.Role`, `.Subrole`, `.Value`, `.ParameterizedAttributeKey`, plus statics on `Accessibility.Notification` and `Action.Name`. These are exhaustive, extracted verbatim from the HIServices headers (including doc comments) by the `generate-ax-constants` plugin. Use them where an API wants raw strings: `copyHierarchy(requesting: [Accessibility.AttributeKey.role, …])`, comparing `try element.role() == Accessibility.Role.button`, etc.

The generated files (`Accessibility+AttributeKey.swift`, `+Role.swift`, `+Subrole.swift`, `+Notification.swift`, `+Action.swift`, `+Value.swift`, `+ParameterizedAttributeKey.swift`) **should not be hand-edited** — regenerate them with:

```sh
swift package generate-ax-constants --allow-writing-to-package-directory
```

## Extending the vocabulary

This is the intended way to work with app-specific or undocumented attributes. Extend `Accessibility.Names` and dynamic member lookup picks it up everywhere:

```swift
extension Accessibility.Names {
    // a read-only attribute holding an element
    var chatTranscript: AttributeName<Accessibility.Element> { "AXChatTranscript" }

    // a writable attribute
    var enhancedUserInterface: MutableAttributeName<Bool> { "AXEnhancedUserInterface" }

    // a parameterized attribute: parameter and return types both declared
    var stringForRange: ParameterizedAttributeName<Range<Int>, String> {
        .init(kAXStringForRangeParameterizedAttribute)
    }

    // an action
    var scrollToTop: ActionName { "AXScrollToTop" }
}

// then, on any element:
let transcript = try app.chatTranscript()
try textField.enhancedUserInterface(assign: true)
let text = try textArea.stringForRange(0..<100)
```

Name types are `ExpressibleByStringLiteral`, so one-off use without touching `Names` also works:

```swift
let attr = element.attribute(Accessibility.Attribute<String>.Name("AXOneOffThing"))
let value = try attr()
```

## Traversal and inspection

- `element.children()` / `element.childrenInNavigationOrder()` / `element.parent()` — one level.
- `element.recursiveChildren()` — lazy breadth-first sequence over the whole subtree. It is guarded by a *traversal complexity budget* (default 3,600 elements-with-children) and terminates early (with an os_log warning) rather than hanging on pathological or cyclic trees. Cycle detection by identity is impossible — see [Sharp edges](#sharp-edges).
- `element.recursivelyFindChild(withID:)` — first descendant matching `AXIdentifier`.
- `element.firstChild(withRole: \.button)` — first direct child with a given role.
- `element.hitTest(at:)` / `element.elementAtScreenPoint(_:)` — element under a screen point. Hit testing only works on **application elements or `.systemWide`**, not arbitrary sub-elements; `elementAtScreenPoint` falls back to system-wide automatically.
- `element.dumpXML(to:)` — pretty XML dump of a subtree (roles as tags, attributes inline, actions and sections included). Great for debugging and for feeding UI state to an LLM; supports `maxDepth`, role/attribute exclusion, and an `excludingPII:` mode that strips titles, values, selected text, file names, etc.
- `element.copyHierarchy(requesting:options:)` — **bulk snapshot in a single IPC round-trip** via the private `AXUIElementCopyHierarchy`. Dramatically faster than per-element attribute fetches for large trees. Returns a `HierarchyResult` keyed by element, with per-attribute `AttributeEntry` values (value, true count when truncated, per-attribute error). Prefer this when you need many attributes across many elements (e.g. building an inspector); prefer plain accessors for a handful of reads.

## Escape hatches: when to go raw

The wrappers are designed to compose with the raw API rather than hide it:

- **`element.raw`** is the `AXUIElement`; any raw HIServices call works on it. Wrap results back with `Element(raw:)` / `Element(erased:)`.
- **Untyped values**: declare `Attribute<Any>` when an attribute's type varies (e.g. `value` on different roles) and pattern-match, or use `Accessibility.Struct` to decode an `AXValue` by hand.
- **Genuinely outside the wrappers**:
  - Entitlement-gated attributes — e.g. `AXClassName` requires the private `com.apple.private.accessibility.inspection` entitlement; the wrapper can name it but macOS will refuse.
  - Text-marker APIs (`AXTextMarkerRef`, `AXTextMarkerRangeRef`) — the parameterized-attribute names exist in the generated constants, but the marker types themselves have no typed wrapper; work with `Attribute<Any>`/raw `CFTypeRef`s.
  - Anything needing exotic setup (`AXUIElementCreateWithRemoteToken`, per-process trust manipulation, …).

## Sharp edges

Non-obvious invariants that will bite you (or an LLM) if unstated:

- **Retain observer tokens.** The subscription lives exactly as long as the `Token`/`AnyCancellable`.
- **Observers need a running run loop** (default `RunLoop.current`).
- **`AXUIElement` instances are not pooled.** Two fetches of the "same" UI object may return different object instances, and an instance may be reused for a different object later. Never dedupe by identity (`ObjectIdentifier`, `Set`); use `==` (`CFEqual`) for point comparisons only. This is also why `recursiveChildren()` uses a complexity budget instead of a visited-set.
- **Everything can throw at any time** — elements are invalidated whenever the target app changes its UI. Treat `try?` on individual reads as normal, not lazy.
- **Hung apps block you.** AX calls into an unresponsive app stall for the default timeout; call `setMessagingTimeout(_:)` on the element (or on `.systemWide` to change the global default for your process) before touching apps you don't control.
- **Type mismatches surface as thrown `.failure`**, not as `nil`. If a read inexplicably fails, re-try with `Attribute<Any>` and look at the real type.
- **Trust is required**: call `Accessibility.isTrusted(shouldPrompt: true)` early; the user grants access in System Settings → Privacy & Security → Accessibility. Sandboxed apps cannot use the AX API on other processes.
- **A few `Names` members are `#if DEBUG`-gated** (`decrement`, `minValue`, `maxValue` in `Names+Standard.swift`) — they vanish in release builds. Use `element.action(.decrement)` / generated constants there instead.
- **Private API is involved**: `element.window()`, `copyHierarchy`, and everything in `WindowControl` use private symbols. They can break across macOS releases and are not App Store-safe. `copyHierarchy` resolves its symbol via `dlsym` at runtime and throws if unavailable.

## Package layout

| Target | What it is |
|---|---|
| `AccessibilityControl` | The AX wrapper — everything in this guide. `import AccessibilityControl`. |
| `WindowControl` | Windows, Spaces, displays, Dock via CoreGraphics + private CGS/SkyLight APIs. See [window-control.md](window-control.md). |
| `CAccessibilityControl` / `CWindowControl` | C shims declaring the private symbols. |
| `AXConstantsGenerator` + `GenerateAXConstants` plugin | Codegen extracting constants from the HIServices headers into `Accessibility+*.swift`. |
| `BetterAccessibilityInspector/` | A SwiftUI accessibility-tree inspector app built on this package — useful as a reference consumer. |
