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

private func isExpectedMissingAttribute(_ error: Error) -> Bool {
    guard let axError = error as? AccessibilityError else { return false }
    return axError.code == .attributeUnsupported || axError.code == .noValue
}

private struct BreadthFirstTraversalState<Node> {
    var queue: [Node]
    var head: Int = 0
    var complexity: Int = 0
}

internal func breadthFirstTraverse<Node>(
    root: Node,
    maxTraversalComplexity: Int,
    onLimitReached: ((Int, Int) -> Void)? = nil,
    childrenOf: @escaping (Node) -> [Node]?
) -> AnySequence<Node> {
    return AnySequence(sequence(state: BreadthFirstTraversalState(queue: [root])) { state -> Node? in
        guard state.complexity < maxTraversalComplexity else {
            let remaining = state.queue.count - state.head
            onLimitReached?(state.complexity, remaining)
            return nil
        }

        guard state.head < state.queue.count else {
            return nil
        }

        let elt = state.queue[state.head]
        state.head += 1
        if state.head >= 64 && state.head * 2 >= state.queue.count {
            state.queue.removeFirst(state.head)
            state.head = 0
        }

        if let children = childrenOf(elt) {
            state.complexity += 1
            state.queue.append(contentsOf: children)
        }
        return elt
    })
}

public extension Accessibility.Element {
    var isValid: Bool {
        (try? pid()) != nil
    }

    var isFrameValid: Bool {
        (try? self.frame()) != nil
    }

    var isInViewport: Bool {
        guard let frame = try? self.frame() else { return false }
        return frame != CGRect.null
    }

    // - breadth-first, seems faster than dfs
    // - default max complexity to 3,600; if i dump the complexity of the Messages app right now i get ~360. x10 that, should be plenty
    // - we can't turn `AXUIElement`s into e.g. `ObjectIdentifier`s and use that to track a set of seen elements and avoid cycles because
    //   the objects aren't pooled; any given instance of `AXUIElement` in memory is "transient" and another may take its place
    func recursiveChildren(maxTraversalComplexity: Int = 3_600) -> AnySequence<Accessibility.Element> {
        recursiveTraversal(label: "children", maxTraversalComplexity: maxTraversalComplexity) { try $0.children() }
    }

    func recursiveSelectedChildren(maxTraversalComplexity: Int = 3_600) -> AnySequence<Accessibility.Element> {
        recursiveTraversal(label: "selected children", maxTraversalComplexity: maxTraversalComplexity) {
            try $0.selectedChildren()
        }
    }

    private func recursiveTraversal(
        label: String,
        maxTraversalComplexity: Int,
        fetch: @escaping (Accessibility.Element) throws -> [Accessibility.Element]
    ) -> AnySequence<Accessibility.Element> {
        breadthFirstTraverse(
            root: self,
            maxTraversalComplexity: maxTraversalComplexity,
            onLimitReached: { complexity, queueCount in
                logAccessibilityError("Recursive \(label) traversal complexity limit hit (\(complexity) >= \(maxTraversalComplexity), queue count: \(queueCount)); terminating early")
            }
        ) { elt in
            do {
                return try fetch(elt)
            } catch {
                if !isExpectedMissingAttribute(error) {
                    logAccessibilityError("Failed to fetch \(label) for \(elt): \(String(describing: error))")
                }
                return nil
            }
        }
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
            throw error
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
