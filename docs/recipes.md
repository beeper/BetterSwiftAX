# Recipes

Small, self-contained examples. Each assumes:

```swift
import AccessibilityControl
```

and that accessibility permission has been granted (first recipe). Concepts are explained in [guide.md](guide.md).

## Check / request accessibility permission

```swift
guard Accessibility.isTrusted(shouldPrompt: true) else {
    // the system shows the grant prompt; the user enables your app in
    // System Settings → Privacy & Security → Accessibility, then relaunch
    return
}
```

## Get an application element

```swift
import AppKit

let app = NSWorkspace.shared.runningApplications
    .first { $0.bundleIdentifier == "com.apple.MobileSMS" }!

let appElement = Accessibility.Element(pid: app.processIdentifier)
// or: app._accessibilityElement
```

## Read attributes (typed, no casts)

```swift
let window = try appElement.appFocusedWindow()   // Accessibility.Element
let title: String = try window.title()
let frame: CGRect = try window.frame()
let role = try window.role()                     // "AXWindow"
let isMinimized = try window.windowIsMinimized()
```

## Write attributes

```swift
try window.position(assign: CGPoint(x: 100, y: 100))
try window.size(assign: CGSize(width: 800, height: 600))
// or both at once:
try window.setFrame(CGRect(x: 100, y: 100, width: 800, height: 600))

try window.windowIsMinimized(assign: true)
```

## Perform actions

```swift
let closeButton = try window.windowCloseButton()
try closeButton.press()

// equivalent shorthand:
try window.closeWindow()

// discover what an element can do:
for action in try element.supportedActions() {
    print(action.name, "-", action.description)
}
```

## Walk the element tree

```swift
// one level
let children = try element.children()

// whole subtree, lazily, breadth-first (bounded — see guide)
for descendant in element.recursiveChildren() {
    if (try? descendant.role()) == Accessibility.Role.button {
        print(try descendant.title())
    }
}

// find by AXIdentifier
let sendButton = appElement.recursivelyFindChild(withID: "send-button")

// first direct child with a role
let toolbar = window.firstChild(withRole: \.toolbar)
```

## Large collections without fetching everything

```swift
let rowCount = try table.rows.count()      // no array fetch
let firstTen = try table.rows(range: 0..<10)
let fifth = try table.rows[4]
```

## Observe notifications

```swift
// the token must be retained — dropping it cancels the subscription
let token = try appElement.observe(.focusedWindowChanged) { info in
    if let element = info["AXUIElement"] as? Accessibility.Element {
        print("focus moved to", (try? element.title()) ?? "?")
    }
}

// Combine flavor (import Combine):
var cancellables = Set<AnyCancellable>()
try window.publisher(for: .windowMoved) { _ in
    print("window moved")
}.store(in: &cancellables)
```

## Element under the mouse

```swift
let point = NSEvent.mouseLocation  // convert to top-left-origin screen coords first
if let element = Accessibility.Element.systemWide.elementAtScreenPoint(point) {
    print(try element.role())
}
```

## App-specific / custom attributes

```swift
extension Accessibility.Names {
    var enhancedUserInterface: MutableAttributeName<Bool> { "AXEnhancedUserInterface" }
}

try appElement.enhancedUserInterface(assign: true)
```

## Parameterized attributes

```swift
extension Accessibility.Names {
    var stringForRange: ParameterizedAttributeName<Range<Int>, String> {
        .init(kAXStringForRangeParameterizedAttribute)
    }
}

let firstHundredChars = try textArea.stringForRange(0..<100)
```

## Dump a subtree as XML (debugging, LLM input)

```swift
var xml = ""
try window.dumpXML(to: &xml, maxDepth: 8, excludingPII: true)
print(xml)
```

## Fast bulk snapshot of a tree (single IPC round-trip)

```swift
let result = try appElement.copyHierarchy(
    requesting: [
        Accessibility.AttributeKey.role,
        Accessibility.AttributeKey.title,
        Accessibility.AttributeKey.children,
    ],
    options: .init(maxArrayCount: 200, returnAttributeErrors: true)
)

for (element, snapshot) in result.allSnapshots() {
    let role = snapshot.entry(for: Accessibility.AttributeKey.role)?.stringValue
    let kids = snapshot.entry(for: Accessibility.AttributeKey.children)?.elementValues
    print(role ?? "?", element, kids?.count ?? 0)
}
```

## Deal with a hung target app

```swift
try appElement.setMessagingTimeout(2)   // seconds; nil resets to default
// ...AX calls to this element now fail fast instead of stalling
```

## From AX element to window ID (and the CGS layer)

```swift
import WindowControl

let cgWindow: Window = try windowElement.window()  // private _AXUIElementGetWindow
let description = try cgWindow.describe()
print(description.ownerName ?? "?", description.bounds)
```

More on `Window`, `Space`, and `Display` in [window-control.md](window-control.md).
