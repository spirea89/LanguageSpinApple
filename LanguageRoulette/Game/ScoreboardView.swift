import SwiftUI

struct ScoreboardView: View {
    let players: [Player]
    let currentPlayerIndex: Int
    let emptyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if players.isEmpty {
                Text(emptyText)
                    .foregroundStyle(AppTheme.muted)
                    .font(AppTheme.rounded(.subheadline, weight: .semibold))
            } else {
                ForEach(sortedPlayers, id: \.player.id) { item in
                    HStack(spacing: 10) {
                        Text(AppTheme.playerEmoji(at: item.index))
                            .font(.title2)
                        Text(item.player.name)
                            .font(AppTheme.rounded(.headline, weight: item.index == currentPlayerIndex ? .heavy : .bold))
                        Spacer()
                        Text("\(item.player.score)")
                            .font(AppTheme.rounded(.title3, weight: .heavy))
                            .foregroundStyle(AppTheme.playerColor(at: item.index))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(item.index == currentPlayerIndex ? AppTheme.gold.opacity(0.32) : AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(item.index == currentPlayerIndex ? AppTheme.gold : AppTheme.line, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var sortedPlayers: [(player: Player, index: Int)] {
        players.enumerated()
            .map { (player: $0.element, index: $0.offset) }
            .sorted { $0.player.score > $1.player.score }
    }
}
