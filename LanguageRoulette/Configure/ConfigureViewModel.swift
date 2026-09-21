#if DEBUG
import Foundation
import SwiftUI

struct EditableQuestion: Identifiable, Equatable {
    let id: UUID
    var prompt: String
    var answer: String

    init(id: UUID = UUID(), prompt: String = "", answer: String = "") {
        self.id = id
        self.prompt = prompt
        self.answer = answer
    }
}

struct EditableCategory: Identifiable, Equatable {
    let uuid: UUID
    var categoryId: String
    var labels: [String: String]
    var questions: [EditableQuestion]

    var id: UUID { uuid }

    init(
        uuid: UUID = UUID(),
        categoryId: String = "",
        labels: [String: String] = [:],
        questions: [EditableQuestion] = []
    ) {
        self.uuid = uuid
        self.categoryId = categoryId
        self.labels = labels
        self.questions = questions
    }

    func displayLabel(languageCode: String, fallback: String) -> String {
        if let value = labels[languageCode], !value.isEmpty { return value }
        if let value = labels[fallback], !value.isEmpty { return value }
        return labels.values.first(where: { !$0.isEmpty }) ?? categoryId
    }
}

@MainActor
final class ConfigureViewModel: ObservableObject {
    @Published var categories: [EditableCategory] = []
    @Published var selectedCategoryID: UUID?
    @Published var labelEditLanguage: String = "en"
    @Published var statusMessage = ""
    @Published var hasUnsavedChanges = false

    private let contentStore: ContentStore

    init(contentStore: ContentStore) {
        self.contentStore = contentStore
        loadFromStore()
    }

    var availableLanguages: [ContentLanguage] {
        contentStore.languages
    }

    func loadFromStore() {
        categories = contentStore.categories.map { category in
            EditableCategory(
                categoryId: category.id,
                labels: category.labels,
                questions: category.questions.map {
                    EditableQuestion(prompt: $0.prompt, answer: $0.answer)
                }
            )
        }
        selectedCategoryID = categories.first?.uuid
        if contentStore.languages.contains(where: { $0.code == labelEditLanguage }) == false {
            labelEditLanguage = contentStore.defaultLanguage
        }
        hasUnsavedChanges = false
        statusMessage = ""
    }

    func addCategory(languageCode: String) {
        let index = categories.count + 1
        let title = contentStore.localized("newQuestionFile", language: languageCode)
        var labels: [String: String] = [:]
        for language in contentStore.languages {
            labels[language.code] = title
        }
        let item = EditableCategory(
            categoryId: "custom-\(index)",
            labels: labels,
            questions: [EditableQuestion(prompt: "Neue Frage?", answer: "")]
        )
        categories.append(item)
        selectedCategoryID = item.uuid
        hasUnsavedChanges = true
        statusMessage = ""
    }

    func deleteCategory(_ item: EditableCategory) {
        categories.removeAll { $0.uuid == item.uuid }
        if selectedCategoryID == item.uuid {
            selectedCategoryID = categories.first?.uuid
        }
        hasUnsavedChanges = true
        statusMessage = ""
    }

    func addQuestion() {
        guard let selectedCategoryID,
              let index = categories.firstIndex(where: { $0.uuid == selectedCategoryID }) else { return }
        categories[index].questions.append(EditableQuestion())
        hasUnsavedChanges = true
        statusMessage = ""
    }

    func deleteQuestion(_ question: EditableQuestion) {
        guard let selectedCategoryID,
              let index = categories.firstIndex(where: { $0.uuid == selectedCategoryID }) else { return }
        categories[index].questions.removeAll { $0.id == question.id }
        hasUnsavedChanges = true
        statusMessage = ""
    }

    func updateLabel(categoryID: UUID, languageCode: String, value: String) {
        guard let index = categories.firstIndex(where: { $0.uuid == categoryID }) else { return }
        categories[index].labels[languageCode] = value
        hasUnsavedChanges = true
        statusMessage = ""
    }

    func save(languageCode: String) {
        do {
            let mapped = categories.compactMap { item -> Category? in
                let id = item.categoryId.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !id.isEmpty else { return nil }
                var labels: [String: String] = [:]
                for (code, value) in item.labels {
                    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        labels[code] = trimmed
                    }
                }
                guard !labels.isEmpty else { return nil }
                let questions = item.questions.compactMap { q -> Question? in
                    let prompt = q.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !prompt.isEmpty else { return nil }
                    return Question(
                        id: "\(id):\(prompt)",
                        prompt: prompt,
                        answer: q.answer.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
                guard !questions.isEmpty else { return nil }
                return Category(id: id, labels: labels, questions: questions)
            }

            var pack = contentStore.pack
            pack.categories = mapped
            try contentStore.save(pack: pack)
            loadFromStore()
            statusMessage = contentStore.localized("savedLocally", language: languageCode)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func resetToDefaults(languageCode: String) {
        do {
            try contentStore.resetToDefaults()
            loadFromStore()
            statusMessage = contentStore.localized("savedLocally", language: languageCode)
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

#endif
