import Foundation

@MainActor
final class ContentStore: ObservableObject {
    @Published private(set) var categories: [Category] = []
    @Published private(set) var loadError: String?

    private let overridesDirectory: URL
    private let categoriesFileName = "categories.txt"

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        overridesDirectory = base.appendingPathComponent("LanguageRoulette/data", isDirectory: true)
        try? fileManager.createDirectory(at: overridesDirectory, withIntermediateDirectories: true)
        reload()
    }

    func reload() {
        do {
            categories = try loadCategories()
            loadError = nil
        } catch {
            categories = []
            loadError = error.localizedDescription
        }
    }

    func resetToDefaults() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: overridesDirectory.path) {
            try fm.removeItem(at: overridesDirectory)
        }
        try fm.createDirectory(at: overridesDirectory, withIntermediateDirectories: true)
        reload()
    }

    func save(categories edited: [Category]) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: overridesDirectory, withIntermediateDirectories: true)

        let categoryLines = edited.map { "\($0.id)|\($0.label)|\($0.file)" }
        let categoriesText = (["# id|Wheel label|Question file"] + categoryLines).joined(separator: "\n") + "\n"
        try categoriesText.write(to: overridesDirectory.appendingPathComponent(categoriesFileName), atomically: true, encoding: .utf8)

        var writtenFiles = Set<String>()
        for category in edited {
            guard !writtenFiles.contains(category.file) else { continue }
            writtenFiles.insert(category.file)
            let questionLines = category.questions.map { question in
                if question.answer.isEmpty {
                    return question.prompt
                }
                return "\(question.prompt)|\(question.answer)"
            }
            let text = (["# Question|Suggested answer"] + questionLines).joined(separator: "\n") + "\n"
            try text.write(to: overridesDirectory.appendingPathComponent(category.file), atomically: true, encoding: .utf8)
        }

        reload()
    }

    // MARK: - Loading

    private func loadCategories() throws -> [Category] {
        let text = try readText(named: categoriesFileName)
        let parsed = Self.parseLines(text).compactMap(Self.parseCategoryLine)
        var result: [Category] = []

        for entry in parsed {
            let questionText = try readText(named: entry.file)
            let questions = Self.parseLines(questionText)
                .compactMap(Self.parseQuestionLine)
                .enumerated()
                .map { index, question in
                    Question(
                        id: "\(entry.id):\(index)",
                        prompt: question.prompt,
                        answer: question.answer
                    )
                }
            guard !questions.isEmpty else { continue }
            result.append(Category(id: entry.id, label: entry.label, file: entry.file, questions: questions))
        }
        return result
    }

    private func readText(named fileName: String) throws -> String {
        let overrideURL = overridesDirectory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: overrideURL.path) {
            return try String(contentsOf: overrideURL, encoding: .utf8)
        }

        let baseName = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension

        let candidates: [URL?] = [
            Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "data"),
            Bundle.main.url(forResource: baseName, withExtension: ext),
            Bundle.main.resourceURL?.appendingPathComponent("data").appendingPathComponent(fileName),
            Bundle.main.resourceURL?.appendingPathComponent("Resources/data").appendingPathComponent(fileName),
            Bundle.main.resourceURL?.appendingPathComponent(fileName)
        ]

        for candidate in candidates {
            guard let url = candidate, FileManager.default.fileExists(atPath: url.path) else { continue }
            return try String(contentsOf: url, encoding: .utf8)
        }

        throw ContentStoreError.missingFile(fileName)
    }

    // MARK: - Parsing (matches web app)

    static func parseLines(_ text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }

    static func parseCategoryLine(_ line: String) -> (id: String, label: String, file: String)? {
        let parts = line.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count == 3, !parts[0].isEmpty, !parts[1].isEmpty, !parts[2].isEmpty else { return nil }
        return (parts[0], parts[1], parts[2])
    }

    static func parseQuestionLine(_ line: String) -> (prompt: String, answer: String)? {
        let parts = line.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let prompt = parts.first, !prompt.isEmpty else { return nil }
        let answer = parts.count > 1 ? parts[1] : ""
        return (prompt, answer)
    }
}

enum ContentStoreError: LocalizedError {
    case missingFile(String)

    var errorDescription: String? {
        switch self {
        case .missingFile(let name):
            return "Could not load \(name)"
        }
    }
}
