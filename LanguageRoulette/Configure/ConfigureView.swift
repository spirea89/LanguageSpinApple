import SwiftUI

struct ConfigureView: View {
    @ObservedObject var viewModel: ConfigureViewModel
    @Binding var language: AppLanguage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(t("configEyebrow"))
                        .font(.caption.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(AppTheme.muted)
                    Text(t("configTitle"))
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppTheme.ink)
                }

                Text(t("staticNote"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)

                categoriesSection
                questionsSection

                HStack(spacing: 10) {
                    Button(t("saveChanges")) {
                        viewModel.save(language: language)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(t("reloadDefaults")) {
                        viewModel.resetToDefaults(language: language)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                if viewModel.hasUnsavedChanges {
                    Text(t("unsaved"))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }

                if !viewModel.statusMessage.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.green)
                }
            }
            .padding(20)
        }
        .background(AppTheme.paper.ignoresSafeArea())
        .onAppear {
            viewModel.loadFromStore()
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(t("categories"))
                    .font(.title3.bold())
                Spacer()
                Button(t("addCategory")) {
                    viewModel.addCategory(language: language)
                }
                .buttonStyle(GhostButtonStyle())
            }

            if viewModel.categories.isEmpty {
                Text(t("noCategories"))
                    .foregroundStyle(AppTheme.muted)
            } else {
                ForEach($viewModel.categories) { $category in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button {
                                viewModel.selectedCategoryID = category.uuid
                            } label: {
                                Text(category.label.isEmpty ? category.categoryId : category.label)
                                    .font(.headline)
                                    .foregroundStyle(viewModel.selectedCategoryID == category.uuid ? AppTheme.accent : AppTheme.ink)
                            }
                            Spacer()
                            Button(t("delete")) {
                                viewModel.deleteCategory(category)
                            }
                            .buttonStyle(GhostButtonStyle())
                        }

                        TextField(t("categoryId"), text: $category.categoryId)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: category.categoryId) { _, _ in
                                viewModel.hasUnsavedChanges = true
                            }
                        TextField(t("wheelLabel"), text: $category.label)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: category.label) { _, _ in
                                viewModel.hasUnsavedChanges = true
                            }
                        TextField(t("questionFile"), text: $category.file)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: category.file) { _, _ in
                                viewModel.hasUnsavedChanges = true
                            }
                    }
                    .padding(14)
                    .background(viewModel.selectedCategoryID == category.uuid ? AppTheme.gold.opacity(0.18) : AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(t("questionsAndAnswers"))
                    .font(.title3.bold())
                Spacer()
                Button(t("addQuestion")) {
                    viewModel.addQuestion()
                }
                .buttonStyle(GhostButtonStyle())
                .disabled(viewModel.selectedCategoryID == nil)
            }

            if let binding = selectedQuestionsBinding {
                ForEach(binding) { $question in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField(t("prompt"), text: $question.prompt)
                            .textFieldStyle(.roundedBorder)
                        TextField(t("answer"), text: $question.answer)
                            .textFieldStyle(.roundedBorder)
                        Button(t("delete")) {
                            viewModel.deleteQuestion(question)
                        }
                        .buttonStyle(GhostButtonStyle())
                    }
                    .padding(14)
                    .background(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: question) { _, _ in
                        viewModel.hasUnsavedChanges = true
                    }
                }
            } else {
                Text(t("noCategories"))
                    .foregroundStyle(AppTheme.muted)
            }
        }
    }

    private var selectedQuestionsBinding: Binding<[EditableQuestion]>? {
        guard let selectedCategoryID = viewModel.selectedCategoryID,
              let index = viewModel.categories.firstIndex(where: { $0.uuid == selectedCategoryID }) else {
            return nil
        }
        return Binding(
            get: { viewModel.categories[index].questions },
            set: {
                viewModel.categories[index].questions = $0
                viewModel.hasUnsavedChanges = true
            }
        )
    }

    private func t(_ key: String) -> String {
        L10n.t(key, language: language)
    }
}
