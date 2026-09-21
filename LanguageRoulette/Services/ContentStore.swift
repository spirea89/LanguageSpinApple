import Foundation

@MainActor
final class ContentStore: ObservableObject {
    @Published private(set) var pack: ContentPack = ContentPack(
        version: 1,
        languages: [
            ContentLanguage(code: "en", name: "English"),
            ContentLanguage(code: "de", name: "Deutsch")
        ],
        defaultLanguage: "en",
        ui: [:],
        categories: []
    )
    @Published private(set) var loadError: String?

    var categories: [Category] { pack.categories }
    var languages: [ContentLanguage] { pack.languages }
    var ui: [String: [String: String]] { pack.ui }
    var defaultLanguage: String { pack.defaultLanguage }

    private let overridesFileName = "content.json"
    private let overridesDirectory: URL

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        overridesDirectory = base.appendingPathComponent("LanguageRoulette/content", isDirectory: true)
        try? fileManager.createDirectory(at: overridesDirectory, withIntermediateDirectories: true)
        reload()
    }

    func reload() {
        do {
            pack = try loadPack()
            loadError = nil
        } catch {
            pack = ContentPack(version: 1, languages: [], defaultLanguage: "en", ui: [:], categories: [])
            loadError = error.localizedDescription
        }
    }

    #if DEBUG
    func resetToDefaults() throws {
        let overrideURL = overridesDirectory.appendingPathComponent(overridesFileName)
        if FileManager.default.fileExists(atPath: overrideURL.path) {
            try FileManager.default.removeItem(at: overrideURL)
        }
        reload()
    }

    func save(pack edited: ContentPack) throws {
        try FileManager.default.createDirectory(at: overridesDirectory, withIntermediateDirectories: true)
        let data = try Self.encode(pack: edited)
        try data.write(to: overridesDirectory.appendingPathComponent(overridesFileName), options: .atomic)
        reload()
    }

    #endif

    func localized(_ key: String, language: String) -> String {
        L10n.t(key, language: language, ui: pack.ui, fallback: pack.defaultLanguage)
    }

    // MARK: - Loading

    private func loadPack() throws -> ContentPack {
        #if DEBUG
        let overrideURL = overridesDirectory.appendingPathComponent(overridesFileName)
        let usingOverride = FileManager.default.fileExists(atPath: overrideURL.path)
        var pack = try Self.decode(data: try readContentData())
        if usingOverride, let bundledData = try? readBundledContentData() {
            let bundled = try Self.decode(data: bundledData)
            pack.ui = Self.mergingMissingUI(from: bundled.ui, into: pack.ui)
        }
        return pack
        #else
        return try Self.decode(data: readBundledContentData())
        #endif
    }

    private func readContentData() throws -> Data {
        let overrideURL = overridesDirectory.appendingPathComponent(overridesFileName)
        #if DEBUG
        if FileManager.default.fileExists(atPath: overrideURL.path) {
            return try Data(contentsOf: overrideURL)
        }
        #endif
        return try readBundledContentData()
    }

    private func readBundledContentData() throws -> Data {
        let candidates: [URL?] = [
            Bundle.main.url(forResource: "content", withExtension: "json", subdirectory: "content"),
            Bundle.main.url(forResource: "content", withExtension: "json"),
            Bundle.main.resourceURL?.appendingPathComponent("content/content.json"),
            Bundle.main.resourceURL?.appendingPathComponent("Resources/content/content.json"),
            Bundle.main.resourceURL?.appendingPathComponent("content.json")
        ]

        for candidate in candidates {
            guard let url = candidate, FileManager.default.fileExists(atPath: url.path) else { continue }
            return try Data(contentsOf: url)
        }

        throw ContentStoreError.missingFile(overridesFileName)
    }

    static func mergingMissingUI(from bundled: [String: [String: String]], into existing: [String: [String: String]]) -> [String: [String: String]] {
        var merged = existing
        for (key, translations) in bundled {
            if merged[key] == nil {
                merged[key] = translations
                continue
            }
            for (language, value) in translations where value.isEmpty == false {
                if merged[key]?[language]?.isEmpty != false {
                    merged[key]?[language] = value
                }
            }
        }
        return merged
    }

    // MARK: - JSON

    static func decode(data: Data) throws -> ContentPack {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json else { throw ContentStoreError.invalidContent }

        let version = json["version"] as? Int ?? 1
        let defaultLanguage = (json["defaultLanguage"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let languageRows = json["languages"] as? [[String: Any]] ?? []
        let languages = languageRows.compactMap { row -> ContentLanguage? in
            guard let code = row["code"] as? String, !code.isEmpty else { return nil }
            let name = (row["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return ContentLanguage(code: code, name: (name?.isEmpty == false ? name! : code))
        }

        guard !languages.isEmpty else { throw ContentStoreError.invalidContent }
        let resolvedDefault = languages.contains(where: { $0.code == defaultLanguage })
            ? (defaultLanguage ?? languages[0].code)
            : languages[0].code

        var ui: [String: [String: String]] = [:]
        if let uiObject = json["ui"] as? [String: Any] {
            for (key, value) in uiObject {
                if let map = value as? [String: String] {
                    ui[key] = map
                } else if let map = value as? [String: Any] {
                    ui[key] = map.compactMapValues { $0 as? String }
                }
            }
        }

        let categoryRows = json["categories"] as? [[String: Any]] ?? []
        let categories: [Category] = categoryRows.compactMap { row in
            guard let id = row["id"] as? String, !id.isEmpty else { return nil }
            var labels: [String: String] = [:]
            if let map = row["labels"] as? [String: String] {
                labels = map
            } else if let map = row["labels"] as? [String: Any] {
                labels = map.compactMapValues { $0 as? String }
            }
            if labels.isEmpty, let legacy = row["label"] as? String {
                labels[resolvedDefault] = legacy
            }

            let questionRows = row["questions"] as? [[String: Any]] ?? []
            let questions = questionRows.enumerated().compactMap { index, qrow -> Question? in
                guard let prompt = qrow["prompt"] as? String else { return nil }
                let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return nil }
                let answer = (qrow["answer"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                return Question(id: "\(id):\(index)", prompt: trimmed, answer: answer)
            }
            guard !questions.isEmpty else { return nil }
            return Category(id: id, labels: labels, questions: questions)
        }

        return ContentPack(
            version: version,
            languages: languages,
            defaultLanguage: resolvedDefault,
            ui: ui,
            categories: categories
        )
    }

    static func encode(pack: ContentPack) throws -> Data {
        let languages = pack.languages.map { ["code": $0.code, "name": $0.name] }
        let categories: [[String: Any]] = pack.categories.map { category in
            [
                "id": category.id,
                "labels": category.labels,
                "questions": category.questions.map { question in
                    [
                        "prompt": question.prompt,
                        "answer": question.answer
                    ]
                }
            ]
        }

        let object: [String: Any] = [
            "version": pack.version,
            "defaultLanguage": pack.defaultLanguage,
            "languages": languages,
            "ui": pack.ui,
            "categories": categories
        ]

        return try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    }
}

enum ContentStoreError: LocalizedError {
    case missingFile(String)
    case invalidContent

    var errorDescription: String? {
        switch self {
        case .missingFile(let name):
            return "Could not load \(name)"
        case .invalidContent:
            return "Content pack is invalid"
        }
    }
}
