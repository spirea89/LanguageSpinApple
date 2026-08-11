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
                    .font(.subheadline)
            } else {
                ForEach(sortedPlayers, id: \.player.id) { item in
                    HStack {
                        Text(item.player.name)
                            .fontWeight(item.index == currentPlayerIndex ? .bold : .semibold)
                        Spacer()
                        Text("\(item.player.score)")
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(item.index == currentPlayerIndex ? AppTheme.gold.opacity(0.25) : AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
