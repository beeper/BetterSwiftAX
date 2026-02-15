import ArgumentParser
import Foundation

// MARK: - Entry Point

@main
struct AXConstantsGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate Swift constant definitions from HIServices AX header files."
    )

    @Argument(help: "Output directory for generated Swift files")
    var outputDirectory: String

    func run() throws {
        let sdkPath = try findSDKPath()
        let headersDir = sdkPath
            + "/System/Library/Frameworks/ApplicationServices.framework"
            + "/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers"

        var allConstants: [Constant] = []
        var commentMap: [String: String] = [:]
        var groupMap: [String: String] = [:]
        var seen: Set<String> = []

        for file in headerFiles {
            let path = headersDir + "/" + file
            let relativeHeaderPath = "System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/\(file)"
            guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
                fputs("warning: could not read \(path)\n", stderr)
                continue
            }
            let metadata = parseHeaderMetadata(from: content)
            commentMap.merge(metadata.comments) { old, _ in old }
            groupMap.merge(metadata.groups) { old, _ in old }
            for c in parseConstants(from: content, sourceHeaderPath: relativeHeaderPath) {
                if seen.insert(c.define).inserted {
                    allConstants.append(c)
                }
            }
        }

        var groups: [String: [Constant]] = [:]
        for c in allConstants {
            groups[c.suffix, default: []].append(c)
        }

        let fm = FileManager.default
        try fm.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)

        var totalCount = 0
        for config in outputConfigs {
            guard let constants = groups[config.suffix], !constants.isEmpty else { continue }
            let content = generateFile(config: config, constants: constants, comments: commentMap, groups: groupMap)
            let path = outputDirectory + "/" + config.fileName
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            totalCount += constants.count
            print("  \(config.fileName) — \(constants.count) constants")
        }
        print("\nGenerated \(totalCount) constants across \(groups.count) files in \(outputDirectory)/")
    }
}

// MARK: - SDK Discovery

private func findSDKPath() throws -> String {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["--show-sdk-path"]
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    try process.run()
    process.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let path = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
          !path.isEmpty else {
        throw ValidationError("Could not determine SDK path. Ensure Xcode or Command Line Tools are installed.")
    }
    return path
}

// MARK: - Configuration

private let headerFiles = [
    "AXRoleConstants.h",
    "AXAttributeConstants.h",
    "AXActionConstants.h",
    "AXNotificationConstants.h",
    "AXValueConstants.h",
    "AXWebConstants.h",
]

private let swiftKeywords: Set<String> = [
    "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
    "func", "import", "init", "inout", "internal", "let", "open", "operator",
    "private", "precedencegroup", "protocol", "public", "rethrows", "static",
    "struct", "subscript", "typealias", "var",
    "break", "case", "catch", "continue", "default", "defer", "do", "else",
    "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch",
    "throw", "where", "while",
    "Any", "as", "false", "is", "nil", "self", "Self", "super",
    "throws", "true", "try",
]

private let skipDefines: Set<String> = ["kAXDescription"]

// MARK: - Output Configuration

private enum OutputMode {
    case caselessEnum(name: String)
    case extensionOnType(typeName: String)
}

private struct OutputConfig {
    let suffix: String
    let mode: OutputMode
    let fileName: String
}

/// Longest suffix first so "ParameterizedAttribute" matches before "Attribute".
private let outputConfigs: [OutputConfig] = [
    .init(suffix: "ParameterizedAttribute", mode: .caselessEnum(name: "ParameterizedAttributeKey"), fileName: "Accessibility+ParameterizedAttributeKey.swift"),
    .init(suffix: "Attribute",              mode: .caselessEnum(name: "AttributeKey"),              fileName: "Accessibility+AttributeKey.swift"),
    .init(suffix: "Subrole",               mode: .caselessEnum(name: "Subrole"),                   fileName: "Accessibility+Subrole.swift"),
    .init(suffix: "Role",                  mode: .caselessEnum(name: "Role"),                      fileName: "Accessibility+Role.swift"),
    .init(suffix: "Notification",          mode: .extensionOnType(typeName: "Notification"),        fileName: "Accessibility+Notification.swift"),
    .init(suffix: "Action",                mode: .extensionOnType(typeName: "Action.Name"),         fileName: "Accessibility+Action.swift"),
    .init(suffix: "Value",                 mode: .caselessEnum(name: "Value"),                      fileName: "Accessibility+Value.swift"),
]

// MARK: - Parsed Constant

private struct Constant {
    let define: String
    let suffix: String
    let sourceHeaderPath: String

    var baseName: String {
        var s = String(define.dropFirst(3)) // strip "kAX"
        if s.hasSuffix(suffix) { s = String(s.dropLast(suffix.count)) }
        return s
    }

    var propertyName: String {
        escaped(lowerCamelCase(baseName))
    }
}

// MARK: - Name Transformation

/// Converts PascalCase to lowerCamelCase, handling leading acronyms.
///
///     "Application"        → "application"
///     "URLDockItem"        → "urlDockItem"
///     "AMPMField"          → "ampmField"
///     "UIElementDestroyed" → "uiElementDestroyed"
private func lowerCamelCase(_ name: String) -> String {
    guard !name.isEmpty else { return name }
    let chars = Array(name)
    var upperCount = 0
    for c in chars {
        guard c.isUppercase else { break }
        upperCount += 1
    }
    if upperCount == 0 { return name }
    if upperCount >= chars.count { return name.lowercased() }
    if upperCount == 1 {
        return String(chars[0]).lowercased() + String(chars[1...])
    }
    return String(chars[0..<(upperCount - 1)]).lowercased()
         + String(chars[(upperCount - 1)...])
}

private func escaped(_ name: String) -> String {
    swiftKeywords.contains(name) ? "`\(name)`" : name
}

// MARK: - Constant Parsing

private let definePattern = try! NSRegularExpression(
    pattern: #"^\s*#define\s+(kAX\w+)\s+CFSTR\("[^"]*"\)"#,
    options: .anchorsMatchLines
)

private func parseConstants(from content: String, sourceHeaderPath: String) -> [Constant] {
    let ns = content as NSString
    let matches = definePattern.matches(in: content, range: NSRange(location: 0, length: ns.length))
    var result: [Constant] = []
    for match in matches {
        let define = ns.substring(with: match.range(at: 1))
        guard !skipDefines.contains(define) else { continue }
        let stripped = String(define.dropFirst(3))
        for config in outputConfigs {
            if stripped.hasSuffix(config.suffix) {
                result.append(Constant(define: define, suffix: config.suffix, sourceHeaderPath: sourceHeaderPath))
                break
            }
        }
    }
    return result
}

// MARK: - Comment & Group Extraction

private struct HeaderMetadata {
    var comments: [String: String]
    var groups: [String: String]
}

private struct BlockCommentCandidate {
    let lines: [String]
    let endLine: Int
}

private struct DocSection {
    let title: String?
    let lines: [String]
}

private struct DefineMatch {
    let name: String
    let trailingComment: String?
}

private struct DoxygenTag {
    let name: String
    let value: String?
}

private let defineLinePattern = try! NSRegularExpression(
    pattern: #"^\s*#define\s+(kAX\w+)\s+CFSTR\("[^"]*"\)(?:\s*//\s*(.*))?\s*$"#
)

private let doxygenTagPattern = try! NSRegularExpression(
    pattern: #"^@([A-Za-z/]+)\b(?:\s+(.*))?$"#
)

private func parseHeaderMetadata(from content: String) -> HeaderMetadata {
    var comments: [String: String] = [:]
    var groups: [String: String] = [:]
    var quickReferenceGroups: [String: String] = [:]

    let lines = content.components(separatedBy: "\n")
    var currentGroup: String?
    var inBlock = false
    var blockLines: [String] = []
    var lastBlockComment: BlockCommentCandidate?
    var lineCommentBuffer: [String] = []
    var lastLineCommentLine = -10_000

    var inQuickReference = false
    var quickReferenceCategory: String?

    for (index, line) in lines.enumerated() {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if let lastBlock = lastBlockComment, (index - lastBlock.endLine) > 3 {
            lastBlockComment = nil
        }

        if inBlock {
            blockLines.append(line)
            updateQuickReferenceState(
                trimmedLine: trimmed,
                inQuickReference: &inQuickReference,
                quickReferenceCategory: &quickReferenceCategory,
                quickReferenceGroups: &quickReferenceGroups
            )
            if trimmed.contains("*/") {
                inBlock = false
                let cleaned = cleanBlockComment(lines: blockLines)
                if let groupName = extractGroupName(from: cleaned) {
                    currentGroup = groupName
                }
                lastBlockComment = BlockCommentCandidate(lines: blockLines, endLine: index)
                blockLines = []
            }
            continue
        }

        if trimmed.hasPrefix("/*") {
            inBlock = true
            blockLines = [line]
            updateQuickReferenceState(
                trimmedLine: trimmed,
                inQuickReference: &inQuickReference,
                quickReferenceCategory: &quickReferenceCategory,
                quickReferenceGroups: &quickReferenceGroups
            )
            if trimmed.contains("*/") {
                inBlock = false
                let cleaned = cleanBlockComment(lines: blockLines)
                if let groupName = extractGroupName(from: cleaned) {
                    currentGroup = groupName
                }
                lastBlockComment = BlockCommentCandidate(lines: blockLines, endLine: index)
                blockLines = []
            }
            lineCommentBuffer.removeAll(keepingCapacity: true)
            continue
        }

        if trimmed.hasPrefix("//") {
            let text = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            if let sectionName = extractSectionHeadingFromLineComment(text) {
                currentGroup = sectionName
                lineCommentBuffer.removeAll(keepingCapacity: true)
            } else if !text.isEmpty {
                lineCommentBuffer.append(text)
                lastLineCommentLine = index
            }
            continue
        }

        if let define = parseDefine(from: line) {
            if let quickReferenceGroup = quickReferenceGroups[define.name] {
                if let currentGroup, isEquivalentGroup(currentGroup, quickReferenceGroup) {
                    groups[define.name] = groups[define.name] ?? currentGroup
                } else {
                    groups[define.name] = groups[define.name] ?? quickReferenceGroup
                }
            } else if let currentGroup {
                groups[define.name] = groups[define.name] ?? currentGroup
            }

            var docParts: [String] = []
            if let lastBlockComment, (index - lastBlockComment.endLine) <= 3 {
                if let documentation = extractDocumentation(from: lastBlockComment.lines) {
                    docParts.append(documentation)
                }
            } else if !lineCommentBuffer.isEmpty, (index - lastLineCommentLine) <= 2 {
                let text = lineCommentBuffer.joined(separator: "\n")
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    docParts.append(text)
                }
            }

            if let trailing = define.trailingComment?.trimmingCharacters(in: .whitespaces),
               !trailing.isEmpty {
                if docParts.isEmpty {
                    docParts.append(trailing)
                } else {
                    docParts.append("Inline Note:\n\(trailing)")
                }
            }

            if !docParts.isEmpty {
                comments[define.name] = comments[define.name] ?? docParts.joined(separator: "\n\n")
            }

            lineCommentBuffer.removeAll(keepingCapacity: true)
            lastBlockComment = nil
            continue
        }

        if !trimmed.isEmpty {
            lineCommentBuffer.removeAll(keepingCapacity: true)
        }
    }

    return HeaderMetadata(comments: comments, groups: groups)
}

private func updateQuickReferenceState(
    trimmedLine: String,
    inQuickReference: inout Bool,
    quickReferenceCategory: inout String?,
    quickReferenceGroups: inout [String: String]
) {
    if trimmedLine.contains("Quick reference:") {
        inQuickReference = true
        quickReferenceCategory = nil
        return
    }

    guard inQuickReference else { return }

    if let heading = parseQuickReferenceHeading(from: trimmedLine) {
        quickReferenceCategory = heading
    } else if let defineName = extractAnyAXDefineName(from: trimmedLine),
              let quickReferenceCategory {
        quickReferenceGroups[defineName] = quickReferenceCategory
    }

    if trimmedLine.contains("*/") {
        inQuickReference = false
        quickReferenceCategory = nil
    }
}

private func parseQuickReferenceHeading(from line: String) -> String? {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    guard trimmed.hasPrefix("//") else { return nil }
    let text = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    guard !text.isEmpty else { return nil }
    guard !text.lowercased().contains("quick reference") else { return nil }
    return normalizedGroupName(text)
}

private func parseDefine(from line: String) -> DefineMatch? {
    let ns = line as NSString
    let range = NSRange(location: 0, length: ns.length)
    guard let match = defineLinePattern.firstMatch(in: line, range: range) else { return nil }
    let name = ns.substring(with: match.range(at: 1))
    let trailingComment: String?
    if match.range(at: 2).location != NSNotFound {
        trailingComment = ns.substring(with: match.range(at: 2))
    } else {
        trailingComment = nil
    }
    return DefineMatch(name: name, trailingComment: trailingComment)
}

private func extractAnyAXDefineName(from line: String) -> String? {
    guard let range = line.range(of: #"\bkAX\w+\b"#, options: .regularExpression) else { return nil }
    return String(line[range])
}

private func cleanBlockComment(lines: [String]) -> [String] {
    let cleaned = lines.map { raw -> String in
        var line = raw
        line = line.replacingOccurrences(
            of: #"^\s*/\*+!?"#,
            with: "",
            options: .regularExpression
        )
        line = line.replacingOccurrences(
            of: #"\*/\s*$"#,
            with: "",
            options: .regularExpression
        )
        line = line.replacingOccurrences(
            of: #"^\s*\* ?"#,
            with: "",
            options: .regularExpression
        )
        return line.trimmingCharacters(in: .whitespaces)
    }
    return trimmingEmptyEdgeLines(cleaned)
}

private func extractGroupName(from cleanedBlock: [String]) -> String? {
    guard !cleanedBlock.isEmpty else { return nil }

    for line in cleanedBlock {
        if let tag = parseDoxygenTag(from: line), tag.name.lowercased() == "group" {
            if let value = tag.value?.trimmingCharacters(in: .whitespaces), !value.isEmpty {
                return normalizedGroupName(value)
            }
        }
    }

    guard cleanedBlock.count == 1 else { return nil }
    let candidate = cleanedBlock[0]
    guard looksLikeSectionHeading(candidate) else { return nil }
    return normalizedGroupName(candidate)
}

private func extractSectionHeadingFromLineComment(_ text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return nil }

    let lower = trimmed.lowercased()
    if lower.contains("cfstringref") || lower.contains("cfbooleanref") || lower.hasSuffix("ref") {
        return nil
    }

    let headingKeywords = [
        "attribute", "attributes",
        "subrole", "subroles",
        "role", "roles",
        "action", "actions",
        "notification", "notifications",
        "value", "values",
    ]
    guard headingKeywords.contains(where: { lower.contains($0) }) else { return nil }
    guard looksLikeSectionHeading(trimmed) else { return nil }
    return normalizedGroupName(trimmed)
}

private func extractDocumentation(from blockLines: [String]) -> String? {
    let cleaned = cleanBlockComment(lines: blockLines)
    guard !cleaned.isEmpty else { return nil }
    if cleaned.allSatisfy({ line in
        line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || line.range(of: #"[A-Za-z0-9]"#, options: .regularExpression) == nil
    }) {
        return nil
    }

    let text = cleaned.joined(separator: "\n")
    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
    if text.contains("Need discussion for following") { return nil }
    if text.contains("@group") { return nil }
    if text.contains("@header") && !text.contains("@defined") && !text.contains("@define") { return nil }
    if cleaned.count == 1 && looksLikeSectionHeading(cleaned[0]) { return nil }

    var sections: [DocSection] = []
    var currentTitle: String?
    var currentLines: [String] = []
    var sawDoxygenTag = false

    func flushSection() {
        let trimmedLines = trimmingEmptyEdgeLines(currentLines)
        guard !trimmedLines.isEmpty else {
            currentLines.removeAll(keepingCapacity: true)
            currentTitle = nil
            return
        }
        sections.append(DocSection(title: currentTitle, lines: trimmedLines))
        currentLines.removeAll(keepingCapacity: true)
        currentTitle = nil
    }

    func startSection(title: String?) {
        flushSection()
        currentTitle = title
    }

    for line in cleaned {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            if !currentLines.isEmpty {
                currentLines.append("")
            }
            continue
        }

        if let tag = parseDoxygenTag(from: trimmed) {
            sawDoxygenTag = true
            let name = tag.name.lowercased()
            let value = tag.value?.trimmingCharacters(in: .whitespaces) ?? ""
            switch name {
            case "define", "defined", "group", "header", "textblock", "/textblock":
                continue
            case "abstract":
                startSection(title: "Abstract")
                if !value.isEmpty { currentLines.append(value) }
            case "discussion":
                startSection(title: "Discussion")
                if !value.isEmpty { currentLines.append(value) }
            case "attributeblock":
                startSection(title: value.isEmpty ? "Attribute" : value)
            default:
                startSection(title: friendlyTagTitle(name))
                if !value.isEmpty { currentLines.append(value) }
            }
            continue
        }

        currentLines.append(trimmed)
    }
    flushSection()

    if sections.isEmpty {
        if sawDoxygenTag { return nil }
        let plain = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return plain.isEmpty ? nil : plain
    }

    var rendered: [String] = []
    for (idx, section) in sections.enumerated() {
        if let title = section.title {
            rendered.append("\(title):")
        }
        rendered.append(contentsOf: section.lines)
        if idx < (sections.count - 1) {
            rendered.append("")
        }
    }

    return rendered.joined(separator: "\n")
}

private func parseDoxygenTag(from line: String) -> DoxygenTag? {
    let ns = line as NSString
    let range = NSRange(location: 0, length: ns.length)
    guard let match = doxygenTagPattern.firstMatch(in: line, range: range) else { return nil }
    let name = ns.substring(with: match.range(at: 1))
    let value: String?
    if match.range(at: 2).location != NSNotFound {
        value = ns.substring(with: match.range(at: 2))
    } else {
        value = nil
    }
    return DoxygenTag(name: name, value: value)
}

private func looksLikeSectionHeading(_ text: String) -> Bool {
    let normalized = text
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespaces)
    guard !normalized.isEmpty else { return false }
    guard normalized.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil else { return false }
    guard !normalized.hasPrefix("@") else { return false }
    guard normalized.count <= 80 else { return false }

    let lower = normalized.lowercased()
    for banned in ["need discussion", "copyright", "quick reference", "tbd", "header"] {
        if lower.contains(banned) { return false }
    }
    return true
}

private func normalizedGroupName(_ text: String) -> String {
    let collapsed = text
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)

    guard !collapsed.isEmpty else { return collapsed }
    if collapsed == collapsed.lowercased(), let first = collapsed.first {
        return String(first).uppercased() + String(collapsed.dropFirst())
    }
    return collapsed
}

private func isEquivalentGroup(_ lhs: String, _ rhs: String) -> Bool {
    normalizeGroupForComparison(lhs) == normalizeGroupForComparison(rhs)
}

private func normalizeGroupForComparison(_ text: String) -> String {
    text
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
}

private func friendlyTagTitle(_ tag: String) -> String {
    switch tag {
    case "seealso":
        return "See Also"
    default:
        return String(tag.prefix(1)).uppercased() + String(tag.dropFirst())
    }
}

private func trimmingEmptyEdgeLines(_ lines: [String]) -> [String] {
    var start = 0
    var end = lines.count

    while start < end, lines[start].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        start += 1
    }
    while end > start, lines[end - 1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        end -= 1
    }
    return Array(lines[start..<end])
}

// MARK: - Code Generation

private func generateFile(
    config: OutputConfig,
    constants: [Constant],
    comments: [String: String],
    groups: [String: String]
) -> String {
    let sourceHeaders = orderedUniqueSourceHeaders(constants)
    let sourceComment = sourceHeaders.count == 1
        ? "// Extracted from: \(sourceHeaders[0])"
        : "// Extracted from: \(sourceHeaders.joined(separator: ", "))"

    var lines: [String] = [
        "import ApplicationServices",
        "",
        sourceComment,
        "",
    ]

    switch config.mode {
    case .caselessEnum(let name):
        lines.append("extension Accessibility {")
        lines.append("    public enum \(name) {")
        appendConstants(
            constants,
            to: &lines,
            comments: comments,
            groups: groups,
            indent: "        "
        ) { constant in
            "public static let \(constant.propertyName) = \(constant.define)"
        }
        lines.append("    }")
        lines.append("}")

    case .extensionOnType(let typeName):
        lines.append("public extension Accessibility.\(typeName) {")
        appendConstants(
            constants,
            to: &lines,
            comments: comments,
            groups: groups,
            indent: "    "
        ) { constant in
            "static let \(constant.propertyName) = Self(\(constant.define))"
        }
        lines.append("}")
    }

    lines.append("")
    return lines.joined(separator: "\n")
}

private func appendConstants(
    _ constants: [Constant],
    to lines: inout [String],
    comments: [String: String],
    groups: [String: String],
    indent: String,
    propertyLine: (Constant) -> String
) {
    let sections = buildConstantSections(constants: constants, groups: groups)
    for (sectionIndex, section) in sections.enumerated() {
        if sectionIndex > 0, lines.last?.isEmpty == false {
            lines.append("")
        }
        if let title = section.title {
            lines.append("\(indent)// MARK: - \(title)")
            lines.append("")
        }

        for constant in section.constants {
            if let comment = comments[constant.define],
               !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                appendDocumentationBlock(comment, indent: indent, to: &lines)
            }
            lines.append("\(indent)\(propertyLine(constant))")
        }
    }
}

private func appendDocumentationBlock(_ comment: String, indent: String, to lines: inout [String]) {
    lines.append("\(indent)/**")
    for line in comment.components(separatedBy: "\n") {
        if line.isEmpty {
            lines.append("\(indent) *")
        } else {
            lines.append("\(indent) * \(line)")
        }
    }
    lines.append("\(indent) */")
}

private struct ConstantSection {
    let title: String?
    var constants: [Constant]
}

private func buildConstantSections(constants: [Constant], groups: [String: String]) -> [ConstantSection] {
    var sections: [ConstantSection] = []
    var sectionIndexByGroupKey: [String: Int] = [:]
    var ungroupedSectionIndex: Int?

    for constant in constants {
        let group = groups[constant.define]?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let group, !group.isEmpty {
            let groupKey = normalizeGroupForComparison(group)
            if let sectionIndex = sectionIndexByGroupKey[groupKey] {
                sections[sectionIndex].constants.append(constant)
            } else {
                sections.append(ConstantSection(title: group, constants: [constant]))
                sectionIndexByGroupKey[groupKey] = sections.count - 1
            }
        } else if let ungroupedSectionIndex {
            sections[ungroupedSectionIndex].constants.append(constant)
        } else {
            sections.append(ConstantSection(title: nil, constants: [constant]))
            ungroupedSectionIndex = sections.count - 1
        }
    }

    return sections
}

private func orderedUniqueSourceHeaders(_ constants: [Constant]) -> [String] {
    var ordered: [String] = []
    var seen: Set<String> = []

    for constant in constants {
        if seen.insert(constant.sourceHeaderPath).inserted {
            ordered.append(constant.sourceHeaderPath)
        }
    }
    return ordered
}
