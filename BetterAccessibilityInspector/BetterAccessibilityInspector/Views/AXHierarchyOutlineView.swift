import AppKit
import SwiftUI

struct AXHierarchyOutlineView: NSViewRepresentable {
    let rootNode: AXHierarchyNode
    var onSelectionChanged: ((AXHierarchyNode?) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.rowSizeStyle = .small
        outlineView.usesAlternatingRowBackgroundColors = false
        outlineView.indentationPerLevel = 14
        outlineView.style = .fullWidth

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AXHierarchyColumn"))
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        outlineView.delegate = context.coordinator
        outlineView.dataSource = context.coordinator

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.documentView = outlineView

        context.coordinator.onSelectionChanged = onSelectionChanged
        context.coordinator.outlineView = outlineView
        context.coordinator.update(rootNode: rootNode)

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.onSelectionChanged = onSelectionChanged
        context.coordinator.update(rootNode: rootNode)
    }

    final class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        weak var outlineView: NSOutlineView?
        private var rootNode: AXHierarchyNode?
        var onSelectionChanged: ((AXHierarchyNode?) -> Void)?

        func update(rootNode: AXHierarchyNode) {
            self.rootNode = rootNode

            guard let outlineView else { return }

            let expandedIDs = expandedNodeIDs(in: outlineView)
            outlineView.reloadData()
            outlineView.expandItem(rootNode)
            restoreExpandedNodeIDs(expandedIDs, in: outlineView)
        }

        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            if item == nil {
                return rootNode == nil ? 0 : 1
            }

            guard let node = item as? AXHierarchyNode else {
                return 0
            }

            return node.children.count
        }

        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            if item == nil {
                return rootNode ?? NSNull()
            }

            guard let node = item as? AXHierarchyNode else {
                return NSNull()
            }

            return node.children[index]
        }

        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            guard let node = item as? AXHierarchyNode else {
                return false
            }

            return !node.children.isEmpty
        }

        func outlineViewSelectionDidChange(_ notification: Notification) {
            guard let outlineView = notification.object as? NSOutlineView else { return }
            let row = outlineView.selectedRow
            let node = row >= 0 ? outlineView.item(atRow: row) as? AXHierarchyNode : nil
            onSelectionChanged?(node)
        }

        func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
            let id = NSUserInterfaceItemIdentifier("AXTableRowView")
            if let existing = outlineView.makeView(withIdentifier: id, owner: nil) as? AXTableRowView {
                return existing
            }
            let rowView = AXTableRowView()
            rowView.identifier = id
            return rowView
        }

        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let node = item as? AXHierarchyNode else {
                return nil
            }

            let identifier = NSUserInterfaceItemIdentifier("AXHierarchyCell")
            let cell: NSTableCellView

            if let existing = outlineView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
                cell = existing
            } else {
                cell = NSTableCellView()
                cell.identifier = identifier

                let textField = NSTextField(labelWithString: "")
                textField.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
                textField.lineBreakMode = .byTruncatingTail
                textField.allowsDefaultTighteningForTruncation = false
                textField.translatesAutoresizingMaskIntoConstraints = false

                cell.addSubview(textField)
                cell.textField = textField

                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                    textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])
            }

            cell.textField?.attributedStringValue = node.attributedDisplayTitle
            cell.textField?.toolTip = node.tooltip

            return cell
        }

        private func expandedNodeIDs(in outlineView: NSOutlineView) -> Set<String> {
            var result: Set<String> = []

            for row in 0..<outlineView.numberOfRows {
                guard let node = outlineView.item(atRow: row) as? AXHierarchyNode else {
                    continue
                }

                if outlineView.isItemExpanded(node) {
                    result.insert(node.id)
                }
            }

            return result
        }

        private func restoreExpandedNodeIDs(_ ids: Set<String>, in outlineView: NSOutlineView) {
            guard !ids.isEmpty else { return }
            expandMatchingNodes(in: outlineView, item: nil, ids: ids)
        }

        private func expandMatchingNodes(in outlineView: NSOutlineView, item: Any?, ids: Set<String>) {
            let childCount = self.outlineView(outlineView, numberOfChildrenOfItem: item)
            guard childCount > 0 else { return }

            for index in 0..<childCount {
                let child = self.outlineView(outlineView, child: index, ofItem: item)

                if let node = child as? AXHierarchyNode, ids.contains(node.id) {
                    outlineView.expandItem(node)
                }

                expandMatchingNodes(in: outlineView, item: child, ids: ids)
            }
        }
    }
}

private class AXTableRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        guard selectionHighlightStyle != .none else { return }
        let rect = bounds.insetBy(dx: 4, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
        if isEmphasized {
            NSColor.controlAccentColor.setFill()
        } else {
            NSColor.unemphasizedSelectedContentBackgroundColor.setFill()
        }
        path.fill()
    }
}
