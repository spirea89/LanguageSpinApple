import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var contentStore: ContentStore

    var body: some View {
        Group {
            if viewModel.gameStarted {
                playingLayout
            } else {
                SetupView(viewModel: viewModel)
            }
        }
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

    // MARK: - Playing (wheel + points)

    private var playingLayout: some View {
        GeometryReader { geo in
            let wheelSide = min(geo.size.width - 28, geo.size.height * 0.36, 300)

            VStack(spacing: 10) {
                playHeader

                wheel(size: wheelSide)

                Text(viewModel.canSpin ? viewModel.t("swipeWheel") : " ")
                    .font(AppTheme.rounded(.caption, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity)

                questionBox

                scoreSection

                compactScoreboard

                HStack(spacing: 10) {
                    Button {
                        viewModel.spin()
                    } label: {
                        Label(viewModel.t("spin"), systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(PrimaryButtonStyle(disabled: !viewModel.canSpin))
                    .disabled(!viewModel.canSpin)

                    Button {
                        viewModel.returnToSetup()
                    } label: {
                        Text(viewModel.t("newGame"))
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var playHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            let index = viewModel.currentPlayerIndex
            Text(AppTheme.playerEmoji(at: index))
                .font(.largeTitle)
                .frame(width: 56, height: 56)
                .background(AppTheme.playerColor(at: index).opacity(0.25))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.t("yourTurn"))
                    .font(AppTheme.rounded(.caption, weight: .heavy))
                    .foregroundStyle(AppTheme.muted)
                Text(viewModel.currentPlayer?.name ?? "-")
                    .font(AppTheme.rounded(.title2, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(viewModel.t("round"))
                    .font(AppTheme.rounded(.caption, weight: .heavy))
                    .foregroundStyle(AppTheme.muted)
                Text(spinStatus)
                    .font(AppTheme.rounded(.title3, weight: .heavy))
                    .foregroundStyle(AppTheme.purple)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.surface.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    private var spinStatus: String {
        if let player = viewModel.currentPlayer {
            return "\(player.spins) / \(viewModel.roundLimit)"
        }
        return "0 / \(viewModel.roundLimit)"
    }

    private var questionBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(viewModel.categoryLabel)
                    .font(AppTheme.rounded(.caption, weight: .heavy))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.gold.opacity(0.45))
                    .clipShape(Capsule())
                Spacer(minLength: 0)
                Button(viewModel.t("replayQuestion")) {
                    viewModel.replayQuestion()
                }
                .font(AppTheme.rounded(.caption, weight: .bold))
                .disabled(!viewModel.canScore)

                Button(viewModel.t("showExample")) {
                    viewModel.showExample()
                }
                .font(AppTheme.rounded(.caption, weight: .bold))
                .disabled(!viewModel.canScore || (viewModel.currentQuestion?.question.answer.isEmpty ?? true))
            }

            Text(viewModel.questionText)
                .font(AppTheme.rounded(.title3, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(4)
                .minimumScaleFactor(0.8)

            if !viewModel.answerText.isEmpty {
                Text(viewModel.answerText)
                    .font(AppTheme.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface.opacity(0.95))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.line, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⭐ \(viewModel.t("scoreAnswer"))")
                .font(AppTheme.rounded(.headline, weight: .heavy))
                .foregroundStyle(AppTheme.ink)

            HStack(spacing: 8) {
                ForEach(viewModel.scoreValues, id: \.self) { points in
                    Button {
                        viewModel.score(points)
                    } label: {
                        VStack(spacing: 2) {
                            Text(AppTheme.scoreEmojis[points] ?? "⭐")
                                .font(.title3)
                            Text("\(points)")
                                .font(AppTheme.rounded(.headline, weight: .heavy))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(viewModel.canScore ? .white : AppTheme.muted)
                        .background(
                            (viewModel.canScore
                             ? (AppTheme.scoreColors[points] ?? AppTheme.ink)
                             : AppTheme.line)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(!viewModel.canScore)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var compactScoreboard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                    VStack(spacing: 2) {
                        Text(AppTheme.playerEmoji(at: index))
                            .font(.title3)
                        Text(player.name)
                            .font(AppTheme.rounded(.caption2, weight: .heavy))
                            .lineLimit(1)
                        Text("\(player.score)")
                            .font(AppTheme.rounded(.headline, weight: .heavy))
                            .foregroundStyle(AppTheme.playerColor(at: index))
                    }
                    .frame(minWidth: 64)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(index == viewModel.currentPlayerIndex ? AppTheme.gold.opacity(0.35) : AppTheme.surface.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                index == viewModel.currentPlayerIndex ? AppTheme.gold : AppTheme.line,
                                lineWidth: 2
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}
