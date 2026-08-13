import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var contentStore: ContentStore

    var body: some View {
        Group {
            switch viewModel.screen {
            case .players:
                playerSetupLayout
            case .categories:
                categorySetupLayout
            case .playing:
                playingLayout
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.screen)
        .background(AppTheme.paper.ignoresSafeArea())
        .overlay {
            if viewModel.showCelebration {
                CelebrationView(
                    eyebrow: viewModel.t("winnerEyebrow"),
                    winners: viewModel.winnerNames,
                    subtitle: "\(viewModel.t("winnerSubtitle")) \(viewModel.winnerScore) \(viewModel.t("points")).",
                    closeTitle: viewModel.t("closeCelebration"),
                    onClose: viewModel.hideCelebration
                )
            }
        }
        .onAppear {
            viewModel.attach(contentStore: contentStore)
        }
        .onChange(of: contentStore.categories) { _, _ in
            viewModel.attach(contentStore: contentStore)
        }
        .onChange(of: viewModel.languageCode) { _, _ in
            viewModel.refreshLanguageLabels()
        }
    }

    // MARK: - Player setup

    private var playerSetupLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                setupHeader(
                    step: 1,
                    eyebrow: viewModel.t("playerSetupEyebrow"),
                    title: viewModel.t("playerSetupTitle"),
                    hint: viewModel.t("playerSetupHint")
                )

                VStack(alignment: .leading, spacing: 16) {
                    setupGrid

                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.t("playerNames"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.muted)

                        ForEach(viewModel.playerNames.indices, id: \.self) { index in
                            TextField("\(viewModel.t("playerName")) \(index + 1)", text: $viewModel.playerNames[index])
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.words)
                        }
                    }

                    Button(viewModel.t("next")) {
                        viewModel.goToCategorySetup()
                    }
                    .buttonStyle(PrimaryButtonStyle(disabled: !viewModel.canAdvanceFromPlayers))
                    .disabled(!viewModel.canAdvanceFromPlayers)
                }
                .padding(16)
                .background(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Category setup

    private var categorySetupLayout: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    setupHeader(
                        step: 2,
                        eyebrow: viewModel.t("categorySetupEyebrow"),
                        title: viewModel.t("categorySetupTitle"),
                        hint: viewModel.t("categorySetupHint")
                    )

                    HStack {
                        Text("\(viewModel.wheelCategories.count) / \(viewModel.allCategories.count) \(viewModel.t("onTheWheel"))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)
                        Spacer()
                        Button(viewModel.t("selectAll")) {
                            viewModel.selectAllCategories()
                        }
                        .font(.subheadline.weight(.semibold))
                        Button(viewModel.t("selectNone")) {
                            viewModel.selectNoCategories()
                        }
                        .font(.subheadline.weight(.semibold))
                    }

                    if viewModel.allCategories.isEmpty {
                        Text(viewModel.t("noCategories"))
                            .foregroundStyle(AppTheme.muted)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(viewModel.allCategories) { category in
                                categoryToggle(category)
                            }
                        }
                    }

                    if !viewModel.canStartGame {
                        Text(viewModel.t("needCategory"))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }

            HStack(spacing: 10) {
                Button(viewModel.t("back")) {
                    viewModel.goBackToPlayers()
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(viewModel.t("startGame")) {
                    viewModel.startGame()
                }
                .buttonStyle(PrimaryButtonStyle(disabled: !viewModel.canStartGame))
                .disabled(!viewModel.canStartGame)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.paper.opacity(0.96))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppTheme.line)
                    .frame(height: 1)
            }
        }
    }

    private func categoryToggle(_ category: Category) -> some View {
        let selected = viewModel.selectedCategoryIDs.contains(category.id)
        return Button {
            viewModel.toggleCategory(category.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? AppTheme.green : AppTheme.muted)
                Text(viewModel.categoryDisplayName(category))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(selected ? AppTheme.gold.opacity(0.28) : AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? AppTheme.gold : AppTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Playing

    private var playingLayout: some View {
        GeometryReader { geo in
            let wheelSide = min(geo.size.width - 24, geo.size.height * 0.38, 280)

            VStack(spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.t("turn"))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.muted)
                        Text(viewModel.currentPlayer?.name ?? "-")
                            .font(.headline)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(viewModel.t("round"))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.muted)
                        Text(spinStatus)
                            .font(.headline)
                    }
                }

                wheel(size: wheelSide)

                Text(viewModel.canSpin ? swipeHint : " ")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity)

                questionBoxCompact

                scoreSection

                compactScoreboard

                HStack(spacing: 8) {
                    Button(viewModel.t("spin")) {
                        viewModel.spin()
                    }
                    .buttonStyle(PrimaryButtonStyle(disabled: !viewModel.canSpin))
                    .disabled(!viewModel.canSpin)

                    Button(viewModel.t("newGame")) {
                        viewModel.newGame()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var swipeHint: String {
        viewModel.languageCode == "de" ? "Rad wischen zum Drehen" : "Swipe the wheel to spin"
    }

    private var setupGrid: some View {
        HStack(spacing: 12) {
            labeledControl(title: viewModel.t("playerCount")) {
                Picker("", selection: $viewModel.playerCount) {
                    ForEach(1...10, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.playerCount) { _, _ in
                    viewModel.onPlayerCountChanged()
                }
            }

            labeledControl(title: viewModel.t("rounds")) {
                Picker("", selection: $viewModel.roundLimit) {
                    ForEach(viewModel.roundOptions, id: \.self) { value in
                        Text(viewModel.t("rounds\(value)")).tag(value)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var spinStatus: String {
        if let player = viewModel.currentPlayer {
            return "\(player.spins) / \(viewModel.roundLimit)"
        }
        return "0 / \(viewModel.roundLimit)"
    }

    private var questionBoxCompact: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(viewModel.categoryLabel)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.gold.opacity(0.35))
                    .clipShape(Capsule())
                Spacer(minLength: 0)
                Button(viewModel.t("replayQuestion")) {
                    viewModel.replayQuestion()
                }
                .font(.caption.weight(.semibold))
                .disabled(!viewModel.canScore)

                Button(viewModel.t("showExample")) {
                    viewModel.showExample()
                }
                .font(.caption.weight(.semibold))
                .disabled(!viewModel.canScore || (viewModel.currentQuestion?.question.answer.isEmpty ?? true))
            }

            Text(viewModel.questionText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(4)
                .minimumScaleFactor(0.85)

            if !viewModel.answerText.isEmpty {
                Text(viewModel.answerText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.t("scoreAnswer"))
                .font(.subheadline.weight(.bold))

            HStack(spacing: 8) {
                ForEach(viewModel.scoreValues, id: \.self) { points in
                    Button("\(points)") {
                        viewModel.score(points)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(viewModel.canScore ? AppTheme.ink : AppTheme.line)
                    .foregroundStyle(viewModel.canScore ? .white : AppTheme.muted)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(!viewModel.canScore)
                }
            }
        }
    }

    private var compactScoreboard: some View {
        HStack(spacing: 6) {
            ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                VStack(spacing: 2) {
                    Text(player.name)
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                    Text("\(player.score)")
                        .font(.subheadline.weight(.heavy))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
                .background(index == viewModel.currentPlayerIndex ? AppTheme.gold.opacity(0.28) : AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func wheel(size: CGFloat) -> some View {
        WheelView(
            categories: viewModel.wheelCategories,
            languageCode: viewModel.languageCode,
            fallbackLanguage: contentStore.defaultLanguage,
            rotation: viewModel.rotation,
            isSpinning: viewModel.spinning,
            canSpin: viewModel.canSpin,
            onSpin: { viewModel.spin() }
        )
        .frame(width: size, height: size)
        .frame(maxWidth: .infinity)
    }

    private func setupHeader(step: Int, eyebrow: String, title: String, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                stepDot(number: 1, active: step == 1, done: step > 1)
                stepDot(number: 2, active: step == 2, done: false)
                Spacer()
                Text(viewModel.t(step == 1 ? "stepPlayers" : "stepCategories"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
            }

            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(AppTheme.muted)
            Text(title)
                .font(.title.bold())
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(hint)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stepDot(number: Int, active: Bool, done: Bool) -> some View {
        Text("\(number)")
            .font(.caption.weight(.heavy))
            .foregroundStyle(active || done ? .white : AppTheme.muted)
            .frame(width: 26, height: 26)
            .background(active || done ? AppTheme.ink : AppTheme.line)
            .clipShape(Circle())
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
