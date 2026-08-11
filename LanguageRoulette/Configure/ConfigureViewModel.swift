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
    var label: String
    var file: String
    var questions: [EditableQuestion]

    var id: UUID { uuid }

    init(
        uuid: UUID = UUID(),
        categoryId: String = "",
        label: String = "",
        file: String = "",
        questions: [EditableQuestion] = []
    ) {
        self.uuid = uuid
        self.categoryId = categoryId
        self.label = label
        self.file = file
        self.questions = questions
    }
}

@MainActor
final class ConfigureViewModel: ObservableObject {
    @Published var categories: [EditableCategory] = []
    @Published var selectedCategoryID: UUID?
    @Published var statusMessage = ""
    @Published var hasUnsavedChanges = false

    private let contentStore: ContentStore

    init(contentStore: ContentStore) {
        self.contentStore = contentStore
        loadFromStore()
    }

    var selectedCategory: Binding<EditableCategory>? {
        guard let selectedCategoryID,
              let index = categories.firstIndex(where: { $0.uuid == selectedCategoryID }) else {
            return nil
        }
        return Binding(
            get: { self.categories[index] },
            set: {
                self.categories[index] = $0
                self.hasUnsavedChanges = true
                self.statusMessage = ""
            }
        )
    }

    func loadFromStore() {
        categories = contentStore.categories.map { category in
            EditableCategory(
                categoryId: category.id,
                label: category.label,
                file: category.file,
                questions: category.questions.map {
                    EditableQuestion(prompt: $0.prompt, answer: $0.answer)
                }
            )
        }
        selectedCategoryID = categories.first?.uuid
        hasUnsavedChanges = false
        statusMessage = ""
    }

    func addCategory(language: AppLanguage) {
        let index = categories.count + 1
        let file = "custom-\(index).txt"
        let item = EditableCategory(
            categoryId: "custom-\(index)",
            label: L10n.t("newQuestionFile", language: language),
            file: file,
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

    func save(language: AppLanguage) {
        do {
            let mapped = categories.compactMap { item -> Category? in
                let id = item.categoryId.trimmingCharacters(in: .whitespacesAndNewlines)
                let label = item.label.trimmingCharacters(in: .whitespacesAndNewlines)
                var file = item.file.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !id.isEmpty, !label.isEmpty else { return nil }
                if file.isEmpty {
                    file = "\(id).txt"
                }
                if !file.hasSuffix(".txt") {
                    file += ".txt"
                }
                let questions = item.questions.compactMap { q -> Question? in
                    let prompt = q.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !prompt.isEmpty else { return nil }
                    return Question(id: "\(id):\(prompt)", prompt: prompt, answer: q.answer.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                guard !questions.isEmpty else { return nil }
                return Category(id: id, label: label, file: file, questions: questions)
            }
            try contentStore.save(categories: mapped)
            loadFromStore()
            statusMessage = L10n.t("savedLocally", language: language)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func resetToDefaults(language: AppLanguage) {
        do {
            try contentStore.resetToDefaults()
            loadFromStore()
            statusMessage = L10n.t("savedLocally", language: language)
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
