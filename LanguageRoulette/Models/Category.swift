import Foundation

struct Category: Identifiable, Equatable, Hashable {
    var id: String
    var label: String
    var file: String
    var questions: [Question]

    init(id: String, label: String, file: String, questions: [Question] = []) {
        self.id = id
        self.label = label
        self.file = file
        self.questions = questions
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
