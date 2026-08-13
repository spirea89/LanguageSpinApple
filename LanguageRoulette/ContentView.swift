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
        ZStack(alignment: .top) {
            PlayfulBackground()

            Group {
                if selectedTab == .game {
                    GameView(viewModel: gameViewModel, contentStore: contentStore)
                } else {
                    ConfigureView(
                        viewModel: configureViewModel,
                        contentStore: contentStore,
                        languageCode: $gameViewModel.languageCode
                    )
                }
            }

            chrome
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

    private var chrome: some View {
        HStack(spacing: 8) {
            if selectedTab == .configure {
                Button {
                    selectedTab = .game
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .glassChip()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(gameViewModel.t("navGame"))
            }

            Spacer()

            Menu {
                Picker(gameViewModel.t("languageLabel"), selection: $gameViewModel.languageCode) {
                    ForEach(gameViewModel.availableLanguages) { language in
                        Text(language.name).tag(language.code)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "globe")
                    Text(gameViewModel.languageCode.uppercased())
                }
                .glassChip()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(gameViewModel.t("languageLabel"))

            if selectedTab == .game {
                Button {
                    selectedTab = .configure
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .bold))
                        .glassChip()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(gameViewModel.t("navConfigure"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .tint(.white)
    }
}

private enum AppTab {
    case game
    case configure
}

#Preview {
    ContentView(contentStore: ContentStore())
}
