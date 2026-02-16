import AppKit

struct RunningApplicationItem: Identifiable {
    let pid: pid_t
    let name: String
    let bundleIdentifier: String?
    let icon: NSImage?
    let activationPolicy: NSApplication.ActivationPolicy

    var id: pid_t { pid }

    init(application: NSRunningApplication) {
        pid = application.processIdentifier
        name = application.localizedName
            ?? application.bundleIdentifier
            ?? "PID \(application.processIdentifier)"
        bundleIdentifier = application.bundleIdentifier
        icon = application.icon
        activationPolicy = application.activationPolicy
    }
}
