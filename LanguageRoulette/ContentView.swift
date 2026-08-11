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
        VStack(spacing: 0) {
            topBar
            TabView(selection: $selectedTab) {
                GameView(viewModel: gameViewModel, contentStore: contentStore)
                    .tag(AppTab.game)

                ConfigureView(viewModel: configureViewModel, language: $gameViewModel.language)
                    .tag(AppTab.configure)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(AppTheme.paper.ignoresSafeArea())
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
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Text("DE")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("Language Roulette")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(AppTheme.ink)
            }

            Spacer()

            HStack(spacing: 6) {
                tabButton(.game, title: gameViewModel.t("navGame"))
                tabButton(.configure, title: gameViewModel.t("navConfigure"))

                Picker(gameViewModel.t("languageLabel"), selection: $gameViewModel.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 110)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.paper.opacity(0.95))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.line)
                .frame(height: 1)
        }
    }

    private func tabButton(_ tab: AppTab, title: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(selectedTab == tab ? AppTheme.ink : AppTheme.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(selectedTab == tab ? AppTheme.surface : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: selectedTab == tab ? AppTheme.ink.opacity(0.06) : .clear, radius: 1, y: 1)
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
