import SwiftUI

struct ContentView: View {
    @ObservedObject var contentStore: ContentStore
    @StateObject private var gameViewModel: GameViewModel
    @StateObject private var configureViewModel: ConfigureViewModel
    @State private var selectedTab: AppTab = .game

    init(contentStore: ContentStore) {
        self.contentStore = contentStore
        _gameViewModel = StateObject(wrappedValue: GameViewModel(contentStore: contentStore))
        _configureViewModel = StateObject(wrappedValue: ConfigureViewModel(contentStore: contentStore))
    }

    var body: some View {
        ZStack {
            PlayfulBackdrop()

            VStack(spacing: 0) {
                topBar
                TabView(selection: $selectedTab) {
                    GameView(viewModel: gameViewModel, contentStore: contentStore)
                        .tag(AppTab.game)

                    ConfigureView(
                        viewModel: configureViewModel,
                        contentStore: contentStore,
                        languageCode: $gameViewModel.languageCode
                    )
                    .tag(AppTab.configure)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .game {
                contentStore.reload()
                gameViewModel.attach(contentStore: contentStore)
            } else {
                configureViewModel.loadFromStore()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("🎡")
                    .font(.title2)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.gold, AppTheme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("Language Roulette")
                    .font(AppTheme.rounded(.headline, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 6) {
                tabButton(.game, title: gameViewModel.t("navGame"), emoji: "🎮")
                tabButton(.configure, title: gameViewModel.t("navConfigure"), emoji: "🛠️")

                Picker(gameViewModel.t("languageLabel"), selection: $gameViewModel.languageCode) {
                    ForEach(gameViewModel.availableLanguages) { language in
                        Text(language.name).tag(language.code)
                    }
                }
                .pickerStyle(.menu)
                .font(AppTheme.rounded(.subheadline, weight: .bold))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.surface.opacity(0.72))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.line)
                .frame(height: 2)
        }
    }

    private func tabButton(_ tab: AppTab, title: String, emoji: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            Text("\(emoji) \(title)")
                .font(AppTheme.rounded(.caption, weight: .heavy))
                .foregroundStyle(selectedTab == tab ? .white : AppTheme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(selectedTab == tab ? AppTheme.purple : AppTheme.surface)
                .clipShape(Capsule())
                .shadow(color: selectedTab == tab ? AppTheme.purple.opacity(0.28) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private enum AppTab {
    case game
    case configure
}

#Preview {
    ContentView(contentStore: ContentStore())
}
