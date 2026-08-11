import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var contentStore: ContentStore

    private var isPlaying: Bool {
        viewModel.gameStarted && !viewModel.gameOver
    }

    var body: some View {
        Group {
            if isPlaying {
                playingLayout
            } else {
                setupLayout
            }
        }
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

    // MARK: - Playing (fits on one screen)

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
                        viewModel.buildPlayers()
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

    // MARK: - Setup

    private var setupLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                wheel(size: 260)

                Text(swipeHint)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity)

                playPanelSetup

                scoreboardSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.t("gameEyebrow"))
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(AppTheme.muted)
            Text(viewModel.t("gameTitle"))
                .font(.title.bold())
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func wheel(size: CGFloat) -> some View {
        WheelView(
            categories: contentStore.categories,
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

    private var playPanelSetup: some View {
        VStack(alignment: .leading, spacing: 14) {
            setupGrid
            playerNames

            Button(viewModel.t("start")) {
                viewModel.spin()
            }
            .buttonStyle(PrimaryButtonStyle(disabled: !viewModel.canSpin))
            .disabled(!viewModel.canSpin)

            HStack(spacing: 10) {
                Button(viewModel.t("newGame")) {
                    viewModel.buildPlayers()
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(viewModel.t("resetScores")) {
                    viewModel.resetScores()
                }
                .buttonStyle(GhostButtonStyle())
            }

            statusStrip
            questionBoxCompact
            scoreSection
        }
        .padding(14)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .disabled(viewModel.setupLocked)
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
                .disabled(viewModel.setupLocked)
            }
        }
    }

    private var playerNames: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.t("playerNames"))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.muted)

            ForEach(viewModel.playerNames.indices, id: \.self) { index in
                TextField("\(viewModel.t("playerName")) \(index + 1)", text: $viewModel.playerNames[index])
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.setupLocked)
            }
        }
    }

    private var statusStrip: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.t("turn"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
                Text(viewModel.currentPlayer?.name ?? "-")
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.t("round"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
                Text(spinStatus)
                    .font(.headline)
            }
        }
        .padding(10)
        .background(AppTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

    private var scoreboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.t("players"))
                .font(.title3.bold())
            ScoreboardView(
                players: viewModel.players,
                currentPlayerIndex: viewModel.currentPlayerIndex,
                emptyText: viewModel.t("noPlayers")
            )
        }
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
