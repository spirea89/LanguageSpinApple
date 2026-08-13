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
                        .font(AppTheme.rounded(.caption, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(t("configTitle"))
                        .font(AppTheme.rounded(.largeTitle, weight: .black))
                        .foregroundStyle(.white)
                }

                Text(t("staticNote"))
                    .font(AppTheme.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))

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
                        .font(AppTheme.rounded(.footnote, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                }

                if !viewModel.statusMessage.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(AppTheme.rounded(.footnote, weight: .semibold))
                        .foregroundStyle(AppTheme.green)
                }
            }
            .padding(20)
            .padding(.top, 40)
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
                    .font(AppTheme.rounded(.title3, weight: .bold))
                    .foregroundStyle(.white)
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
                    .foregroundStyle(.white.opacity(0.75))
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
                            .buttonStyle(GhostButtonStyle(onDark: false))
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
                    .background(viewModel.selectedCategoryID == category.uuid ? AppTheme.gold.opacity(0.22) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.cardLine, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .colorScheme(.light)
                }
            }
        }
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(t("questionsAndAnswers"))
                    .font(AppTheme.rounded(.title3, weight: .bold))
                    .foregroundStyle(.white)
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
                        .buttonStyle(GhostButtonStyle(onDark: false))
                    }
                    .padding(14)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.cardLine, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .colorScheme(.light)
                    .onChange(of: question) { _, _ in
                        viewModel.hasUnsavedChanges = true
                    }
                }
            } else {
                Text(t("noCategories"))
                    .foregroundStyle(.white.opacity(0.75))
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
                .font(AppTheme.rounded(.caption, weight: .bold))
                .foregroundStyle(.white.opacity(0.75))
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .colorScheme(.light)
        }
    }

    private func t(_ key: String) -> String {
        contentStore.localized(key, language: languageCode)
    }
}
