import AppKit
import AccessibilityControl

final class AXHierarchyNode: NSObject {
    let id: String
    let role: String
    let subrole: String?
    let title: String?
    let identifier: String?
    let valueDescription: String?
    let isIncomplete: Bool
    let rawElementDescription: String
    let children: [AXHierarchyNode]
    let element: Accessibility.Element?

    init(
        id: String,
        role: String,
        subrole: String?,
        title: String?,
        identifier: String?,
        valueDescription: String?,
        isIncomplete: Bool,
        rawElementDescription: String,
        children: [AXHierarchyNode],
        element: Accessibility.Element? = nil
    ) {
        self.id = id
        self.role = role
        self.subrole = subrole
        self.title = title
        self.identifier = identifier
        self.valueDescription = valueDescription
        self.isIncomplete = isIncomplete
        self.rawElementDescription = rawElementDescription
        self.children = children
        self.element = element
    }

    var displayTitle: String {
        var parts: [String] = [role]

        if let subrole = subrole?.nonEmpty {
            parts.append("(\(subrole))")
        }

        if let title = title?.nonEmpty {
            parts.append("\"\(title.truncated(to: 80))\"")
        } else if let identifier = identifier?.nonEmpty {
            parts.append("#\(identifier.truncated(to: 80))")
        } else if let valueDescription = valueDescription?.nonEmpty {
            parts.append("= \(valueDescription.truncated(to: 80))")
        }

        if isIncomplete {
            parts.append("[incomplete]")
        }

        return parts.joined(separator: " ")
    }

    var attributedDisplayTitle: NSAttributedString {
        let result = NSMutableAttributedString()
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let space = NSAttributedString(string: " ", attributes: [.font: font])

        // Role — cyan
        result.append(NSAttributedString(
            string: role,
            attributes: [.font: font, .foregroundColor: NSColor.systemCyan]
        ))

        // Subrole — blue
        if let subrole = subrole?.nonEmpty {
            result.append(space)
            result.append(NSAttributedString(
                string: "(\(subrole))",
                attributes: [.font: font, .foregroundColor: NSColor.systemBlue]
            ))
        }

        // Title — yellow
        if let title = title?.nonEmpty {
            result.append(space)
            result.append(NSAttributedString(
                string: "\"\(title.truncated(to: 80))\"",
                attributes: [.font: font, .foregroundColor: NSColor.systemYellow]
            ))
        }

        // Identifier — green
        if let identifier = identifier?.nonEmpty {
            result.append(space)
            result.append(NSAttributedString(
                string: "#\(identifier.truncated(to: 80))",
                attributes: [.font: font, .foregroundColor: NSColor.systemGreen]
            ))
        }

        // Value — purple
        if let valueDescription = valueDescription?.nonEmpty {
            result.append(space)
            result.append(NSAttributedString(
                string: "= \(valueDescription.truncated(to: 80))",
                attributes: [.font: font, .foregroundColor: NSColor.systemPurple]
            ))
        }

        // Incomplete — red
        if isIncomplete {
            result.append(space)
            result.append(NSAttributedString(
                string: "[incomplete]",
                attributes: [.font: font, .foregroundColor: NSColor.systemRed]
            ))
        }

        return result
    }

    var tooltip: String {
        var lines: [String] = [rawElementDescription]

        if let identifier = identifier?.nonEmpty {
            lines.append("Identifier: \(identifier)")
        }
        if let valueDescription = valueDescription?.nonEmpty {
            lines.append("Value: \(valueDescription)")
        }

        return lines.joined(separator: "\n")
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func truncated(to limit: Int) -> String {
        guard count > limit else { return self }
        return prefix(limit) + "..."
    }
}
