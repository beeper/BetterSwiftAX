import SwiftUI

struct RunningApplicationRowView: View {
    let application: RunningApplicationItem

    var body: some View {
        HStack(spacing: 8) {
            if let icon = application.icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 16, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Image(systemName: "app")
                    .frame(width: 16, height: 16)
            }

            Text(application.name)
                .lineLimit(1)
        }
        .help(application.bundleIdentifier ?? "PID \(application.pid)")
    }
}
