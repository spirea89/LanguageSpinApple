import Foundation
import SwiftUI

struct ActiveQuestion: Equatable {
    let category: Category
    let question: Question
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published var playerCount: Int = 2
    @Published var playerNames: [String] = ["Player 1", "Player 2"]
    @Published var roundLimit: Int = 10
    @Published var languageCode: String {
        didSet { UserDefaults.standard.set(languageCode, forKey: "roata-language") }
    }

    @Published private(set) var players: [Player] = []
    @Published private(set) var currentPlayerIndex: Int = 0
    @Published private(set) var rotation: Double = 0
    @Published private(set) var spinning = false
    @Published private(set) var gameStarted = false
    @Published private(set) var gameOver = false
    @Published private(set) var currentQuestion: ActiveQuestion?
    @Published private(set) var exampleVisible = false
    @Published private(set) var categoryLabel = ""
    @Published private(set) var questionText = ""
    @Published private(set) var answerText = ""
    @Published private(set) var showCelebration = false
    @Published private(set) var winnerNames = ""
    @Published private(set) var winnerScore = 0

    private var askedQuestionKeys = Set<String>()
    private var messageKey = "intro"
    private var spinGeneration = 0
    private let speech = SpeechService()
    private weak var contentStore: ContentStore?

    let scoreValues = [0, 10, 30, 45]
    let roundOptions = [5, 10, 20, 30]

    var categories: [Category] {
        contentStore?.categories ?? []
    }

    var availableLanguages: [ContentLanguage] {
        contentStore?.languages ?? []
    }

    var setupLocked: Bool {
        gameStarted && !gameOver
    }

    var currentPlayer: Player? {
        guard players.indices.contains(currentPlayerIndex) else { return nil }
        return players[currentPlayerIndex]
    }

    var canSpin: Bool {
        currentQuestion == nil
            && !spinning
            && !gameOver
            && !players.isEmpty
            && !categories.isEmpty
    }

    var canScore: Bool {
        currentQuestion != nil && !spinning && !gameOver
    }

    init(contentStore: ContentStore) {
        let saved = UserDefaults.standard.string(forKey: "roata-language")
        let fallback = contentStore.defaultLanguage
        if let saved, contentStore.languages.contains(where: { $0.code == saved }) {
            self.languageCode = saved
        } else {
            self.languageCode = fallback
        }
        self.contentStore = contentStore
        syncPlayerNameFields()
        buildPlayers()
        applyMessageState()
    }

    func attach(contentStore: ContentStore) {
        self.contentStore = contentStore
        if !contentStore.languages.contains(where: { $0.code == languageCode }) {
            languageCode = contentStore.defaultLanguage
        }
        if let error = contentStore.loadError {
            categoryLabel = t("dataError")
            questionText = error
            answerText = ""
        } else {
            refreshLanguageLabels()
        }
    }

    func t(_ key: String) -> String {
        contentStore?.localized(key, language: languageCode)
            ?? L10n.t(key, language: languageCode, ui: [:], fallback: "en")
    }

    func categoryDisplayName(_ category: Category) -> String {
        category.label(for: languageCode, fallback: contentStore?.defaultLanguage ?? "en")
    }

    func syncPlayerNameFields() {
        let existing = playerNames
        playerNames = (0..<playerCount).map { index in
            if index < existing.count {
                let trimmed = existing[index].trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? "\(t("playerName")) \(index + 1)" : existing[index]
            }
            return "\(t("playerName")) \(index + 1)"
        }
    }

    func onPlayerCountChanged() {
        syncPlayerNameFields()
        if !setupLocked {
            buildPlayers()
        }
    }

    func startGame() {
        buildPlayers()
        guard !players.isEmpty, !categories.isEmpty else { return }
        gameStarted = true
        messageKey = "pressStart"
        let name = players[currentPlayerIndex].name
        setMessage(categoryKey: "nextTurn", promptKey: "pressStart", detail: "\(name),")
    }

    func returnToSetup() {
        buildPlayers()
    }

    func buildPlayers() {
        speech.cancel()
        spinGeneration += 1
        spinning = false
        let names = playerNames.enumerated().map { index, name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "\(t("playerName")) \(index + 1)" : trimmed
        }
        players = names.map { Player(name: $0) }
        currentPlayerIndex = 0
        askedQuestionKeys.removeAll()
        currentQuestion = nil
        exampleVisible = false
        gameStarted = false
        gameOver = false
        showCelebration = false
        messageKey = "intro"
        setMessage(categoryKey: "spinToChoose", promptKey: "intro", detail: "")
    }

    func resetScores() {
        speech.cancel()
        spinGeneration += 1
        spinning = false
        for index in players.indices {
            players[index].score = 0
            players[index].spins = 0
        }
        currentPlayerIndex = 0
        askedQuestionKeys.removeAll()
        currentQuestion = nil
        exampleVisible = false
        gameOver = false
        gameStarted = false
        showCelebration = false
        messageKey = "scoresReset"
        setMessage(categoryKey: "spinToChoose", promptKey: "scoresReset", detail: "")
    }

    func spin() {
        guard gameStarted else { return }
        guard canSpin else { return }

        speech.cancel()
        spinning = true
        gameStarted = true
        currentQuestion = nil
        exampleVisible = false
        messageKey = "getReady"
        setMessage(categoryKey: "spinning", promptKey: "getReady", detail: "")

        let categoryIndex = Int.random(in: 0..<categories.count)
        let step = 360.0 / Double(categories.count)
        let targetMiddle = Double(categoryIndex) * step + step / 2
        let pointerAngle = 0.0
        let extraTurns = 5 + Int.random(in: 0..<3)
        let currentRotation = normalizeDegrees(rotation)
        let targetRotation = normalizeDegrees(pointerAngle - targetMiddle)
        let spinDelta = Double(extraTurns) * 360 + normalizeDegrees(targetRotation - currentRotation)
        rotation += spinDelta

        spinGeneration += 1
        let generation = spinGeneration
        Task {
            try? await Task.sleep(nanoseconds: 4_900_000_000)
            guard generation == spinGeneration, spinning else { return }
            let category = categories[categoryIndex]
            let question = pickQuestion(from: category)
            currentQuestion = ActiveQuestion(category: category, question: question)
            exampleVisible = false
            spinning = false
            setQuestion(category: categoryDisplayName(category), prompt: question.prompt, answer: question.answer)
            speech.speakGerman(question.prompt)
        }
    }

    func score(_ points: Int) {
        guard currentQuestion != nil, !gameOver else { return }

        players[currentPlayerIndex].score += points
        players[currentPlayerIndex].spins += 1
        currentQuestion = nil
        exampleVisible = false
        speech.cancel()

        if players.allSatisfy({ $0.spins >= roundLimit }) {
            gameOver = true
            let winnerScoreValue = players.map(\.score).max() ?? 0
            let winners = players.filter { $0.score == winnerScoreValue }.map(\.name).joined(separator: ", ")
            messageKey = ""
            setQuestion(category: t("gameOver"), prompt: "\(winners) \(t("wonWith")) \(winnerScoreValue) \(t("points")).", answer: "")
            winnerNames = winners
            winnerScore = winnerScoreValue
            showCelebration = true
        } else {
            repeat {
                currentPlayerIndex = (currentPlayerIndex + 1) % players.count
            } while players[currentPlayerIndex].spins >= roundLimit
            messageKey = "pressStart"
            let name = players[currentPlayerIndex].name
            setMessage(categoryKey: "nextTurn", promptKey: "pressStart", detail: "\(name),")
        }
    }

    func replayQuestion() {
        guard let active = currentQuestion, !spinning, !gameOver else { return }
        speech.speakGerman(active.question.prompt)
    }

    func showExample() {
        guard let active = currentQuestion, !active.question.answer.isEmpty else { return }
        exampleVisible = true
        setQuestion(category: categoryDisplayName(active.category), prompt: active.question.prompt, answer: active.question.answer)
    }

    func hideCelebration() {
        showCelebration = false
    }

    func refreshLanguageLabels() {
        syncPlayerNameFields()
        if let active = currentQuestion {
            setQuestion(category: categoryDisplayName(active.category), prompt: active.question.prompt, answer: active.question.answer)
        } else {
            applyMessageState()
        }
    }

    // MARK: - Private

    private func pickQuestion(from category: Category) -> Question {
        let available = category.questions.filter { !askedQuestionKeys.contains($0.key) }
        let pool = available.isEmpty ? category.questions : available
        let question = pool.randomElement() ?? category.questions[0]
        askedQuestionKeys.insert(question.key)
        return question
    }

    private func setQuestion(category: String, prompt: String, answer: String) {
        messageKey = ""
        categoryLabel = category
        questionText = prompt
        if exampleVisible, !answer.isEmpty {
            answerText = "\(t("suggestedAnswer")): \(answer)"
        } else {
            answerText = ""
        }
    }

    private func setMessage(categoryKey: String, promptKey: String, detail: String) {
        messageKey = promptKey
        categoryLabel = t(categoryKey)
        questionText = detail.isEmpty ? t(promptKey) : "\(detail) \(t(promptKey))"
        exampleVisible = false
        answerText = ""
    }

    private func applyMessageState() {
        if let active = currentQuestion {
            setQuestion(category: categoryDisplayName(active.category), prompt: active.question.prompt, answer: active.question.answer)
        } else if messageKey == "intro" {
            setMessage(categoryKey: "spinToChoose", promptKey: "intro", detail: "")
        } else if messageKey == "getReady" {
            setMessage(categoryKey: "spinning", promptKey: "getReady", detail: "")
        } else if messageKey == "scoresReset" {
            setMessage(categoryKey: "spinToChoose", promptKey: "scoresReset", detail: "")
        } else if messageKey == "pressStart" {
            let detail = currentPlayer.map { "\($0.name)," } ?? ""
            setMessage(categoryKey: "nextTurn", promptKey: "pressStart", detail: detail)
        } else {
            setMessage(categoryKey: "spinToChoose", promptKey: "intro", detail: "")
        }
    }

    private func normalizeDegrees(_ value: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: 360)
        return result >= 0 ? result : result + 360
    }
}
