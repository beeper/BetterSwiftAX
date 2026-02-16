import SwiftUI

struct InspectorDetailView: View {
    let model: AccessibilityInspectorModel

    var body: some View {
        Group {
            if !model.isAccessibilityTrusted {
                VStack(spacing: 12) {
                    Text("Accessibility access is required.")
                        .foregroundStyle(.secondary)
                    Button("Grant Accessibility Access") {
                        model.requestAccessibilityPermission()
                    }
                }
            } else if model.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .padding()
            } else if let rootNode = model.rootNode {
                AXHierarchyOutlineView(rootNode: rootNode, onSelectionChanged: model.selectNode)
            } else {
                Text("Select an application")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: model.reloadTree) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Reload accessibility tree")
            }
        }
    }
}
