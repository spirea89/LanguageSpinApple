import SwiftUI

struct ConfigureView: View {
    @ObservedObject var viewModel: ConfigureViewModel
    @ObservedObject var contentStore: ContentStore
    @Binding var languageCode: String

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
                        viewModel.save(languageCode: languageCode)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(t("reloadDefaults")) {
                        viewModel.resetToDefaults(languageCode: languageCode)
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
        .background(Color.clear)
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
                    viewModel.addCategory(languageCode: languageCode)
                }
                .buttonStyle(GhostButtonStyle())
            }

            labeledControl(title: t("editLanguage")) {
                Picker("", selection: $viewModel.labelEditLanguage) {
                    ForEach(viewModel.availableLanguages) { language in
                        Text(language.name).tag(language.code)
                    }
                }
                .pickerStyle(.menu)
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
                                Text(
                                    category.displayLabel(
                                        languageCode: languageCode,
                                        fallback: contentStore.defaultLanguage
                                    )
                                )
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

                        TextField(
                            "\(t("wheelLabel")) (\(viewModel.labelEditLanguage))",
                            text: bindingForLabel(categoryID: category.uuid)
                        )
                        .textFieldStyle(.roundedBorder)
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

    private func bindingForLabel(categoryID: UUID) -> Binding<String> {
        Binding(
            get: {
                guard let category = viewModel.categories.first(where: { $0.uuid == categoryID }) else { return "" }
                return category.labels[viewModel.labelEditLanguage] ?? ""
            },
            set: { viewModel.updateLabel(categoryID: categoryID, languageCode: viewModel.labelEditLanguage, value: $0) }
        )
    }

    private func labeledControl<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.muted)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(AppTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func t(_ key: String) -> String {
        contentStore.localized(key, language: languageCode)
    }
}
