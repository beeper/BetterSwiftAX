import SwiftUI

struct ApplicationSidebarView: View {
    let applications: [RunningApplicationItem]
    @Binding var selection: pid_t?
    let refreshAction: () -> Void

    var body: some View {
        List(selection: $selection) {
            ForEach(applications) { application in
                RunningApplicationRowView(application: application)
                    .tag(Optional(application.pid))
            }
        }
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: refreshAction) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh running applications")
            }
        }
    }
}
