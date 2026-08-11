import Foundation

struct ContentLanguage: Identifiable, Equatable, Hashable, Codable {
    var code: String
    var name: String

    var id: String { code }
}

struct Category: Identifiable, Equatable, Hashable {
    var id: String
    var labels: [String: String]
    var questions: [Question]

    init(id: String, labels: [String: String], questions: [Question] = []) {
        self.id = id
        self.labels = labels
        self.questions = questions
    }

    func label(for languageCode: String, fallback: String = "en") -> String {
        if let value = labels[languageCode], !value.isEmpty {
            return value
        }
        if let value = labels[fallback], !value.isEmpty {
            return value
        }
        return labels.values.first(where: { !$0.isEmpty }) ?? id
    }
}

struct Question: Identifiable, Equatable, Hashable {
    var id: String
    var prompt: String
    var answer: String

    init(id: String, prompt: String, answer: String = "") {
        self.id = id
        self.prompt = prompt
        self.answer = answer
    }

    var key: String { id }
}

struct Player: Identifiable, Equatable {
    let id: UUID
    var name: String
    var score: Int
    var spins: Int

    init(id: UUID = UUID(), name: String, score: Int = 0, spins: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
        self.spins = spins
    }
}

struct ContentPack: Equatable {
    var version: Int
    var languages: [ContentLanguage]
    var defaultLanguage: String
    var ui: [String: [String: String]]
    var categories: [Category]
}
