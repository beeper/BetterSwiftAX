import ApplicationServices
import AccessibilityControl
import Foundation

struct AXHierarchyBuilder {
    private static let requestedAttributes: [String] = [
        kAXRoleAttribute,
        kAXSubroleAttribute,
        kAXTitleAttribute,
        kAXIdentifierAttribute,
        kAXValueAttribute,
        kAXChildrenAttribute,
    ]

    static func buildTree(for application: RunningApplicationItem) throws -> AXHierarchyNode {
        let rootElement = Accessibility.Element(pid: application.pid)
        let options = Accessibility.HierarchyOptions(
            arrayAttributes: [kAXChildrenAttribute],
            maxDepth: 120,
            truncateStrings: true
        )

        let hierarchy = try rootElement.copyHierarchy(
            requesting: requestedAttributes,
            options: options
        )

        let index = SnapshotIndex(snapshots: hierarchy.allSnapshots())

        return buildNode(
            element: rootElement,
            appName: application.name,
            snapshotIndex: index,
            ancestors: []
        )
    }

    private static func buildNode(
        element: Accessibility.Element,
        appName: String,
        snapshotIndex: SnapshotIndex,
        ancestors: Set<ElementIdentity>
    ) -> AXHierarchyNode {
        let identity = ElementIdentity(element)

        if ancestors.contains(identity) {
            return AXHierarchyNode(
                id: identity.id,
                role: "AXCycle",
                subrole: nil,
                title: nil,
                identifier: nil,
                valueDescription: nil,
                isIncomplete: true,
                rawElementDescription: String(describing: element.raw),
                children: [],
                element: nil
            )
        }

        let snapshot = snapshotIndex.snapshot(for: element)
        let role = snapshot?.entry(for: kAXRoleAttribute)?.stringValue ?? "AXUnknown"
        let subrole = snapshot?.entry(for: kAXSubroleAttribute)?.stringValue
        let title = snapshot?.entry(for: kAXTitleAttribute)?.stringValue ?? (role == kAXApplicationRole ? appName : nil)
        let identifier = snapshot?.entry(for: kAXIdentifierAttribute)?.stringValue
        let valueDescription = stringify(snapshot?.entry(for: kAXValueAttribute)?.value)

        var nextAncestors = ancestors
        nextAncestors.insert(identity)

        let childElements = snapshot?.entry(for: kAXChildrenAttribute)?.elementValues ?? []
        let children = childElements.map {
            buildNode(
                element: $0,
                appName: appName,
                snapshotIndex: snapshotIndex,
                ancestors: nextAncestors
            )
        }

        return AXHierarchyNode(
            id: identity.id,
            role: role,
            subrole: subrole,
            title: title,
            identifier: identifier,
            valueDescription: valueDescription,
            isIncomplete: snapshot?.isIncomplete == true,
            rawElementDescription: String(describing: element.raw),
            children: children,
            element: element
        )
    }

    private static func stringify(_ value: Any?) -> String? {
        guard let value else { return nil }

        if let value = value as? String {
            return value
        }
        if let value = value as? Bool {
            return value ? "true" : "false"
        }
        if let value = value as? NSNumber {
            return value.stringValue
        }
        if let value = value as? [Any] {
            return "[\(value.count) items]"
        }

        return String(describing: value)
    }
}

private struct SnapshotIndex {
    private let snapshots: [(element: Accessibility.Element, snapshot: Accessibility.HierarchyResult.ElementSnapshot)]
    private let buckets: [Int: [Int]]

    init(snapshots: [(element: Accessibility.Element, snapshot: Accessibility.HierarchyResult.ElementSnapshot)]) {
        self.snapshots = snapshots

        var buckets: [Int: [Int]] = [:]
        for (index, entry) in snapshots.enumerated() {
            let hash = Int(CFHash(entry.element.raw))
            buckets[hash, default: []].append(index)
        }
        self.buckets = buckets
    }

    func snapshot(for element: Accessibility.Element) -> Accessibility.HierarchyResult.ElementSnapshot? {
        let hash = Int(CFHash(element.raw))
        guard let indexes = buckets[hash] else { return nil }

        for index in indexes where snapshots[index].element == element {
            return snapshots[index].snapshot
        }

        return nil
    }
}

private struct ElementIdentity: Hashable {
    let id: String

    init(_ element: Accessibility.Element) {
        let pid = (try? element.pid()) ?? 0
        let hash = CFHash(element.raw)
        let rawDescription = String(describing: element.raw)
        id = "\(pid):\(hash):\(rawDescription)"
    }
}
