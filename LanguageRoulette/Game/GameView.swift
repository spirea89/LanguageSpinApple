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
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: viewModel.screen)
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
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    setupHero(
                        step: 1,
                        icon: "person.3.fill",
                        title: viewModel.t("playerSetupTitle"),
                        hint: viewModel.t("playerSetupHint")
                    )

                    VStack(spacing: 18) {
                        stepperRow(
                            title: viewModel.t("playerCount"),
                            value: "\(viewModel.playerCount)",
                            minusEnabled: viewModel.playerCount > 1,
                            plusEnabled: viewModel.playerCount < 10,
                            onMinus: {
                                viewModel.playerCount = max(1, viewModel.playerCount - 1)
                                viewModel.onPlayerCountChanged()
                            },
                            onPlus: {
                                viewModel.playerCount = min(10, viewModel.playerCount + 1)
                                viewModel.onPlayerCountChanged()
                            }
                        )

                        avatarRow

                        stepperRow(
                            title: viewModel.t("rounds"),
                            value: "\(viewModel.roundLimit)",
                            minusEnabled: viewModel.roundLimit > (viewModel.roundOptions.first ?? 5),
                            plusEnabled: viewModel.roundLimit < (viewModel.roundOptions.last ?? 30),
                            onMinus: { bumpRounds(-1) },
                            onPlus: { bumpRounds(1) }
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Text(viewModel.t("playerNames"))
                                .font(AppTheme.rounded(.subheadline, weight: .bold))
                                .foregroundStyle(AppTheme.muted)

                            ForEach(viewModel.playerNames.indices, id: \.self) { index in
                                playerNameRow(index: index)
                            }
                        }
                    }
                    .padding(18)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 20, y: 10)
                    .colorScheme(.light)
                }
                .padding(.horizontal, 18)
                .padding(.top, 52)
                .padding(.bottom, 16)
            }

            Button {
                viewModel.goToCategorySetup()
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.t("next"))
                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.black))
                }
            }
            .buttonStyle(PrimaryButtonStyle(disabled: !viewModel.canAdvanceFromPlayers))
            .disabled(!viewModel.canAdvanceFromPlayers)
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
    }

    private var avatarRow: some View {
        HStack(spacing: -8) {
            ForEach(0..<viewModel.playerCount, id: \.self) { index in
                Text(playerInitial(index))
                    .font(AppTheme.rounded(.subheadline, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.playerColor(index))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .zIndex(Double(20 - index))
            }
            Spacer(minLength: 0)
        }
    }

    private func playerNameRow(index: Int) -> some View {
        HStack(spacing: 10) {
            Text(playerInitial(index))
                .font(AppTheme.rounded(.headline, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(AppTheme.playerColor(index))
                .clipShape(Circle())

            TextField("\(viewModel.t("playerName")) \(index + 1)", text: $viewModel.playerNames[index])
                .font(AppTheme.rounded(.body, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(red: 0.95, green: 0.93, blue: 0.99))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .textInputAutocapitalization(.words)
        }
    }

    // MARK: - Category setup

    private var categorySetupLayout: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    setupHero(
                        step: 2,
                        icon: "sparkles",
                        title: viewModel.t("categorySetupTitle"),
                        hint: viewModel.t("categorySetupHint")
                    )

                    HStack {
                        Text("\(viewModel.wheelCategories.count) / \(viewModel.allCategories.count) \(viewModel.t("onTheWheel"))")
                            .font(AppTheme.rounded(.subheadline, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                        Button(viewModel.t("selectAll")) {
                            viewModel.selectAllCategories()
                        }
                        .buttonStyle(GhostButtonStyle())
                        Button(viewModel.t("selectNone")) {
                            viewModel.selectNoCategories()
                        }
                        .buttonStyle(GhostButtonStyle())
                    }

                    if viewModel.allCategories.isEmpty {
                        Text(viewModel.t("noCategories"))
                            .foregroundStyle(.white.opacity(0.8))
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(Array(viewModel.allCategories.enumerated()), id: \.element.id) { index, category in
                                categoryToggle(category, color: AppTheme.playerColor(index))
                            }
                        }
                    }

                    if !viewModel.canStartGame {
                        Text(viewModel.t("needCategory"))
                            .font(AppTheme.rounded(.footnote, weight: .bold))
                            .foregroundStyle(AppTheme.gold)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 52)
                .padding(.bottom, 16)
            }

            HStack(spacing: 12) {
                Button(viewModel.t("back")) {
                    viewModel.goBackToPlayers()
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    viewModel.startGame()
                } label: {
                    HStack(spacing: 8) {
                        Text(viewModel.t("startGame"))
                        Image(systemName: "play.fill")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(disabled: !viewModel.canStartGame))
                .disabled(!viewModel.canStartGame)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
    }

    private func categoryToggle(_ category: Category, color: Color) -> some View {
        let selected = viewModel.selectedCategoryIDs.contains(category.id)
        return Button {
            viewModel.toggleCategory(category.id)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 14, height: 14)
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(selected ? .white : .white.opacity(0.45))
                }
                Text(viewModel.categoryDisplayName(category))
                    .font(AppTheme.rounded(.subheadline, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(selected ? color.opacity(0.95) : .white.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(selected ? Color.white.opacity(0.45) : Color.white.opacity(0.16), lineWidth: 1.5)
            )
            .shadow(color: selected ? color.opacity(0.45) : .clear, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Playing

    private var playingLayout: some View {
        GeometryReader { geo in
            let wheelSide = min(geo.size.width - 28, geo.size.height * 0.36, 270)

            VStack(spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    if let player = viewModel.currentPlayer {
                        Text(String(player.name.prefix(1)).uppercased())
                            .font(AppTheme.rounded(.headline, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.playerColor(viewModel.currentPlayerIndex))
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(viewModel.t("turn"))
                            .font(AppTheme.rounded(.caption2, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(viewModel.currentPlayer?.name ?? "-")
                            .font(AppTheme.rounded(.headline, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(viewModel.t("round"))
                            .font(AppTheme.rounded(.caption2, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(spinStatus)
                            .font(AppTheme.rounded(.headline, weight: .heavy))
                            .foregroundStyle(AppTheme.gold)
                    }
                }
                .padding(.top, 52)

                wheel(size: wheelSide)

                Text(viewModel.canSpin ? swipeHint : " ")
                    .font(AppTheme.rounded(.caption, weight: .bold))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity)

                questionBoxCompact

                scoreSection

                compactScoreboard

                HStack(spacing: 10) {
                    Button {
                        viewModel.spin()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(viewModel.t("spin"))
                        }
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
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var swipeHint: String {
        viewModel.languageCode == "de" ? "Wisch übers Rad!" : "Swipe the wheel!"
    }

    private var spinStatus: String {
        if let player = viewModel.currentPlayer {
            return "\(player.spins) / \(viewModel.roundLimit)"
        }
        return "0 / \(viewModel.roundLimit)"
    }

    private var questionBoxCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(viewModel.categoryLabel)
                    .font(AppTheme.rounded(.caption, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.gold)
                    .clipShape(Capsule())
                Spacer(minLength: 0)
                Button(viewModel.t("replayQuestion")) {
                    viewModel.replayQuestion()
                }
                .font(AppTheme.rounded(.caption, weight: .bold))
                .foregroundStyle(AppTheme.violet)
                .disabled(!viewModel.canScore)

                Button(viewModel.t("showExample")) {
                    viewModel.showExample()
                }
                .font(AppTheme.rounded(.caption, weight: .bold))
                .foregroundStyle(AppTheme.violet)
                .disabled(!viewModel.canScore || (viewModel.currentQuestion?.question.answer.isEmpty ?? true))
            }

            Text(viewModel.questionText)
                .font(AppTheme.rounded(.body, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(4)
                .minimumScaleFactor(0.85)

            if !viewModel.answerText.isEmpty {
                Text(viewModel.answerText)
                    .font(AppTheme.rounded(.caption, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .colorScheme(.light)
    }

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.t("scoreAnswer"))
                .font(AppTheme.rounded(.subheadline, weight: .bold))
                .foregroundStyle(.white.opacity(0.88))

            HStack(spacing: 8) {
                ForEach(Array(viewModel.scoreValues.enumerated()), id: \.element) { index, points in
                    Button("\(points)") {
                        viewModel.score(points)
                    }
                    .font(AppTheme.rounded(.title3, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.canScore ? AppTheme.scoreColors[index] : .white.opacity(0.14))
                    .foregroundStyle(viewModel.canScore ? (index == 3 ? AppTheme.ink : .white) : .white.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: viewModel.canScore ? AppTheme.scoreColors[index].opacity(0.35) : .clear, radius: 8, y: 4)
                    .disabled(!viewModel.canScore)
                }
            }
        }
    }

    private var compactScoreboard: some View {
        HStack(spacing: 8) {
            ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                VStack(spacing: 4) {
                    Text(String(player.name.prefix(1)).uppercased())
                        .font(AppTheme.rounded(.caption, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(AppTheme.playerColor(index))
                        .clipShape(Circle())
                    Text(player.name)
                        .font(AppTheme.rounded(.caption2, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(player.score)")
                        .font(AppTheme.rounded(.headline, weight: .black))
                        .foregroundStyle(AppTheme.gold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(index == viewModel.currentPlayerIndex ? .white.opacity(0.18) : .white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(index == viewModel.currentPlayerIndex ? AppTheme.gold : Color.white.opacity(0.08), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    private func setupHero(step: Int, icon: String, title: String, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                stepCoin(number: 1, active: step == 1, done: step > 1)
                Capsule()
                    .fill(.white.opacity(0.28))
                    .frame(width: 18, height: 4)
                stepCoin(number: 2, active: step == 2, done: false)
                Spacer()
            }

            HStack(alignment: .center, spacing: 10) {
                Image(systemName: icon)
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.gold)
                Text(title)
                    .font(AppTheme.rounded(.title, weight: .black))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(hint)
                .font(AppTheme.rounded(.body, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stepCoin(number: Int, active: Bool, done: Bool) -> some View {
        Text(done ? "✓" : "\(number)")
            .font(AppTheme.rounded(.caption, weight: .black))
            .foregroundStyle(active || done ? AppTheme.ink : .white.opacity(0.7))
            .frame(width: 30, height: 30)
            .background(active || done ? AppTheme.gold : .white.opacity(0.16))
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
            .shadow(color: active ? AppTheme.gold.opacity(0.45) : .clear, radius: 8)
    }

    private func stepperRow(
        title: String,
        value: String,
        minusEnabled: Bool,
        plusEnabled: Bool,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.rounded(.subheadline, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            HStack(spacing: 12) {
                roundIconButton("minus", enabled: minusEnabled, action: onMinus)
                Text(value)
                    .font(AppTheme.rounded(.title3, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(minWidth: 36)
                roundIconButton("plus", enabled: plusEnabled, action: onPlus)
            }
        }
    }

    private func roundIconButton(_ systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(enabled ? AppTheme.violet : AppTheme.muted.opacity(0.4))
                .clipShape(Circle())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }

    private func bumpRounds(_ direction: Int) {
        guard let current = viewModel.roundOptions.firstIndex(of: viewModel.roundLimit) else { return }
        let next = current + direction
        guard viewModel.roundOptions.indices.contains(next) else { return }
        viewModel.roundLimit = viewModel.roundOptions[next]
    }

    private func playerInitial(_ index: Int) -> String {
        let name = viewModel.playerNames.indices.contains(index) ? viewModel.playerNames[index] : ""
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String((trimmed.isEmpty ? "\(index + 1)" : trimmed).prefix(1)).uppercased()
    }
}
