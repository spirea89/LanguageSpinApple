import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var contentStore: ContentStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 28) {
                        wheelColumn
                            .frame(maxWidth: 420)
                        playPanel
                            .frame(maxWidth: 420)
                    }
                    VStack(alignment: .leading, spacing: 24) {
                        wheelColumn
                        playPanel
                    }
                }

                scoreboardSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.t("gameEyebrow"))
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(AppTheme.muted)
            Text(viewModel.t("gameTitle"))
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var wheelColumn: some View {
        WheelView(
            categories: contentStore.categories,
            languageCode: viewModel.languageCode,
            fallbackLanguage: contentStore.defaultLanguage,
            rotation: viewModel.rotation,
            isSpinning: viewModel.spinning
        )
        .frame(maxWidth: .infinity)
        .frame(height: 320)
    }

    private var playPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            setupGrid
            playerNames
            buttonRow
            statusStrip
            questionBox
            scoreSection
        }
        .padding(18)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppTheme.ink.opacity(0.06), radius: 16, y: 8)
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
        VStack(alignment: .leading, spacing: 10) {
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

    private var buttonRow: some View {
        VStack(spacing: 10) {
            Button(viewModel.gameStarted && !viewModel.gameOver ? viewModel.t("spin") : viewModel.t("start")) {
                viewModel.spin()
            }
            .buttonStyle(PrimaryButtonStyle(disabled: !viewModel.canSpin))
            .disabled(!viewModel.canSpin)

            HStack(spacing: 10) {
                Button(viewModel.t("newGame")) {
                    viewModel.buildPlayers()
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(viewModel.setupLocked)

                Button(viewModel.t("resetScores")) {
                    viewModel.resetScores()
                }
                .buttonStyle(GhostButtonStyle())
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
        .padding(12)
        .background(AppTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var spinStatus: String {
        if let player = viewModel.currentPlayer {
            return "\(player.spins) / \(viewModel.roundLimit)"
        }
        return "0 / \(viewModel.roundLimit)"
    }

    private var questionBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.categoryLabel)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.gold.opacity(0.35))
                .clipShape(Capsule())

            Text(viewModel.t("question"))
                .font(.title3.bold())

            Text(viewModel.questionText)
                .font(.body)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button(viewModel.t("replayQuestion")) {
                    viewModel.replayQuestion()
                }
                .buttonStyle(GhostButtonStyle())
                .disabled(!viewModel.canScore)

                Button(viewModel.t("showExample")) {
                    viewModel.showExample()
                }
                .buttonStyle(GhostButtonStyle())
                .disabled(!viewModel.canScore || (viewModel.currentQuestion?.question.answer.isEmpty ?? true))
            }

            if !viewModel.answerText.isEmpty {
                Text(viewModel.answerText)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
        }
    }

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.t("scoreAnswer"))
                .font(.headline)

            HStack(spacing: 10) {
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

    private var scoreboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
