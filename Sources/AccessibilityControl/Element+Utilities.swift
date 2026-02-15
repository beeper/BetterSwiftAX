import CoreFoundation
import Foundation
import OSLog

@available(macOS 11.0, *)
private let accessibilityLogger = Logger(subsystem: "com.betterswiftax", category: "accessibility")

private func logAccessibilityError(_ message: String) {
    if #available(macOS 11.0, *) {
        accessibilityLogger.error("\(message, privacy: .public)")
    } else {
        NSLog("%@", message)
    }
}

public extension Accessibility.Element {
    var isValid: Bool {
        do {
            _ = try pid()
            return true
        } catch {
            logAccessibilityError("Failed to validate AX element pid for \(self): \(String(describing: error))")
            return false
        }
    }

    var isFrameValid: Bool {
        do {
            _ = try self.frame()
            return true
        } catch {
            logAccessibilityError("Failed to validate AX frame for \(self): \(String(describing: error))")
            return false
        }
    }

    var isInViewport: Bool {
        do {
            return try self.frame() != CGRect.null
        } catch {
            logAccessibilityError("Failed to check viewport visibility for \(self): \(String(describing: error))")
            return false
        }
    }

    // - breadth-first, seems faster than dfs
    // - default max complexity to 1,800; if i dump the complexity of the Messages app right now i get ~360. x10 that, should be plenty
    // - we can't turn `AXUIElement`s into e.g. `ObjectIdentifier`s and use that to track a set of seen elements and avoid cycles because
    //   the objects aren't pooled; any given instance of `AXUIElement` in memory is "transient" and another may take its place
    func recursiveChildren(maxTraversalComplexity: Int = 3_600) -> AnySequence<Accessibility.Element> {
        // incremented for every element with children that we discover; not "depth" since it's a running tally
        var traversalComplexity = 0

        return AnySequence(sequence(state: [self] as [Accessibility.Element]) { queue -> Accessibility.Element? in
            guard traversalComplexity < maxTraversalComplexity else {
                let queueCount = queue.count
                logAccessibilityError("Recursive traversal complexity limit hit (\(traversalComplexity) >= \(maxTraversalComplexity), queue count: \(queueCount)); terminating early")
                return nil
            }

            guard !queue.isEmpty else {
                // queue is empty, we're done
                return nil
            }

            let elt = queue.removeFirst()

            do {
                let children = try elt.children()
                defer { traversalComplexity += 1 }
                queue.append(contentsOf: children)
            } catch {
                logAccessibilityError("Failed to fetch children for \(elt): \(String(describing: error))")
            }
            return elt
        })
    }

    func recursiveSelectedChildren() -> AnySequence<Accessibility.Element> {
        AnySequence(sequence(state: [self]) { queue -> Accessibility.Element? in
            guard !queue.isEmpty else { return nil }
            let elt = queue.removeFirst()
            do {
                let selectedChildren = try elt.selectedChildren()
                queue.append(contentsOf: selectedChildren)
            } catch {
                logAccessibilityError("Failed to fetch selected children for \(elt): \(String(describing: error))")
            }
            return elt
        })
    }

    func recursivelyFindChild(withID id: String) -> Accessibility.Element? {
        recursiveChildren().lazy.first {
            (try? $0.identifier()) == id
        }
    }

    func setFrame(_ frame: CGRect) throws {
        do {
            try self.position(assign: frame.origin)
            try self.size(assign: frame.size)
        } catch {
            logAccessibilityError("Failed to set frame for \(self): \(String(describing: error))")
            
            return error
        }
    }

    func closeWindow() throws {
        do {
            let closeButton = try self.windowCloseButton()
            try closeButton.press()
        } catch {
            logAccessibilityError("Could not close window for \(self): \(String(describing: error))")
            throw error
        }
    }
}

public extension Accessibility.Element {
    func firstChild(withRole role: KeyPath<Accessibility.Role.Type, String>) -> Accessibility.Element? {
        try? self.children().first { child in
            (try? child.role()) == Accessibility.Role.self[keyPath: role]
        }
    }
}
