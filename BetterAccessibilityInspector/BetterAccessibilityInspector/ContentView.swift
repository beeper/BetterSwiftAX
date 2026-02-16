import SwiftUI

struct ContentView: View {
    @State private var model = AccessibilityInspectorModel()

    var body: some View {
        NavigationSplitView {
            ApplicationSidebarView(
                applications: model.filteredApplications,
                selection: Binding(
                    get: { model.selectedApplicationPID },
                    set: { model.selectedApplicationPID = $0 }
                ),
                refreshAction: model.refreshApplications
            )
            .searchable(
                text: Binding(
                    get: { model.searchText },
                    set: { model.searchText = $0 }
                ),
                prompt: "Search applications"
            )
            .frame(minWidth: 220)
        } detail: {
            InspectorDetailView(model: model)
        }
        .frame(minWidth: 900, minHeight: 560)
        .task {
            model.start()
        }
        .onChange(of: model.selectedApplicationPID) { _, _ in
            model.handleSelectionChange()
        }
    }
}

#Preview {
    ContentView()
}
