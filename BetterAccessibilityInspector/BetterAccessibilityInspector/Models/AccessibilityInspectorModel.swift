import AppKit
import AccessibilityControl
import Observation

@MainActor
@Observable
final class AccessibilityInspectorModel {
    var applications: [RunningApplicationItem] = []
    var selectedApplicationPID: pid_t?
    var rootNode: AXHierarchyNode?
    var errorMessage: String?
    var isLoading = false
    var isAccessibilityTrusted = Accessibility.isTrusted()
    var searchText: String = ""

    var filteredApplications: [RunningApplicationItem] {
        let filtered = applications.filter { $0.activationPolicy == .regular }
        guard !searchText.isEmpty else { return filtered }
        return filtered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.bundleIdentifier?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var hasStarted = false
    private var treeLoadTask: Task<Void, Never>?
    private var overlayWindow: HighlightOverlayWindow?

    var selectedApplication: RunningApplicationItem? {
        guard let pid = selectedApplicationPID else { return nil }
        return applications.first(where: { $0.pid == pid })
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        refreshApplications()
    }

    func refreshApplications() {
        let newApplications = NSWorkspace.shared.runningApplications
            .filter { !$0.isTerminated }
            .map(RunningApplicationItem.init(application:))
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

        applications = newApplications

        if let selectedApplicationPID,
           newApplications.contains(where: { $0.pid == selectedApplicationPID }) {
            // Keep current selection.
        } else {
            selectedApplicationPID = newApplications.first?.pid
        }

        scheduleTreeReload()
    }

    func handleSelectionChange() {
        scheduleTreeReload()
    }

    func reloadTree() {
        scheduleTreeReload()
    }

    func requestAccessibilityPermission() {
        isAccessibilityTrusted = Accessibility.isTrusted(shouldPrompt: true)
        scheduleTreeReload()
    }

    func selectNode(_ node: AXHierarchyNode?) {
        guard let element = node?.element,
              let position = try? element.position(),
              let size = try? element.size(),
              size.width > 0, size.height > 0 else {
            overlayWindow?.hide()
            return
        }

        if overlayWindow == nil {
            overlayWindow = HighlightOverlayWindow()
        }
        overlayWindow?.highlight(axFrame: CGRect(origin: position, size: size))
    }

    private func scheduleTreeReload() {
        treeLoadTask?.cancel()
        overlayWindow?.hide()

        treeLoadTask = Task { [weak self] in
            await Task.yield()
            guard let self else { return }
            await self.loadTreeForSelectedApplication()
        }
    }

    private func loadTreeForSelectedApplication() async {
        isAccessibilityTrusted = Accessibility.isTrusted()

        guard isAccessibilityTrusted else {
            rootNode = nil
            errorMessage = "Accessibility permission is required."
            isLoading = false
            return
        }

        guard let selectedApplication else {
            rootNode = nil
            errorMessage = nil
            isLoading = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        if Task.isCancelled { return }

        do {
            let root = try AXHierarchyBuilder.buildTree(for: selectedApplication)
            if Task.isCancelled { return }
            rootNode = root
            errorMessage = nil
        } catch {
            if Task.isCancelled { return }
            rootNode = nil
            errorMessage = String(describing: error)
        }
    }
}
