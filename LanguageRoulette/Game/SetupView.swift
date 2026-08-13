import SwiftUI

struct SetupView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                playerCountCard
                namesCard
                roundsCard

                Button {
                    viewModel.startGame()
                } label: {
                    Label(viewModel.t("startGame"), systemImage: "sparkles")
                }
                .buttonStyle(PrimaryButtonStyle(disabled: viewModel.categories.isEmpty))
                .disabled(viewModel.categories.isEmpty)

                Text(viewModel.t("intro"))
                    .font(AppTheme.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .padding(.bottom, 24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🎡 \(viewModel.t("settingsEyebrow"))")
                .font(AppTheme.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(AppTheme.purple)
            Text(viewModel.t("settingsTitle"))
                .font(AppTheme.rounded(.largeTitle, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(viewModel.t("settingsSubtitle"))
                .font(AppTheme.rounded(.body, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.top, 4)
    }

    private var playerCountCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("👫 \(viewModel.t("choosePlayers"))")
                .font(AppTheme.rounded(.headline, weight: .heavy))
                .foregroundStyle(AppTheme.ink)

            HStack(spacing: 16) {
                countButton(symbol: "minus", enabled: viewModel.playerCount > 1) {
                    viewModel.playerCount = max(1, viewModel.playerCount - 1)
                    viewModel.onPlayerCountChanged()
                }

                VStack(spacing: 2) {
                    Text("\(viewModel.playerCount)")
                        .font(AppTheme.rounded(.largeTitle, weight: .heavy))
                        .foregroundStyle(AppTheme.accentStrong)
                        .contentTransition(.numericText())
                    Text(viewModel.playerCount == 1 ? viewModel.t("soloPlayer") : viewModel.t("friends"))
                        .font(AppTheme.rounded(.caption, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                }
                .frame(maxWidth: .infinity)

                countButton(symbol: "plus", enabled: viewModel.playerCount < 10) {
                    viewModel.playerCount = min(10, viewModel.playerCount + 1)
                    viewModel.onPlayerCountChanged()
                }
            }
        }
        .kidCard()
    }

    private var namesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("✏️ \(viewModel.t("playerNames"))")
                .font(AppTheme.rounded(.headline, weight: .heavy))
                .foregroundStyle(AppTheme.ink)

            ForEach(viewModel.playerNames.indices, id: \.self) { index in
                HStack(spacing: 10) {
                    Text(AppTheme.playerEmoji(at: index))
                        .font(.title)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.playerColor(at: index).opacity(0.22))
                        .clipShape(Circle())

                    TextField("\(viewModel.t("playerName")) \(index + 1)", text: $viewModel.playerNames[index])
                        .font(AppTheme.rounded(.title3, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .kidCard()
    }

    private var roundsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔄 \(viewModel.t("chooseRounds"))")
                .font(AppTheme.rounded(.headline, weight: .heavy))
                .foregroundStyle(AppTheme.ink)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(viewModel.roundOptions, id: \.self) { value in
                    Button {
                        viewModel.roundLimit = value
                    } label: {
                        Text(viewModel.t("rounds\(value)"))
                    }
                    .buttonStyle(
                        KidChipStyle(
                            selected: viewModel.roundLimit == value,
                            color: AppTheme.blue
                        )
                    )
                }
            }
        }
        .kidCard()
    }

    private func countButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.heavy))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(enabled ? AppTheme.purple : AppTheme.muted.opacity(0.35))
                .clipShape(Circle())
                .shadow(color: enabled ? AppTheme.purple.opacity(0.3) : .clear, radius: 6, y: 3)
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

private extension View {
    func kidCard() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.line, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: AppTheme.ink.opacity(0.06), radius: 10, y: 4)
    }
}
