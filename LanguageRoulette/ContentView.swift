import SwiftUI

struct ContentView: View {
    @ObservedObject var contentStore: ContentStore
    @StateObject private var gameViewModel: GameViewModel
    #if DEBUG
    @StateObject private var configureViewModel: ConfigureViewModel
    @State private var selectedTab: AppTab = .game
    #endif

    init(contentStore: ContentStore) {
        self.contentStore = contentStore
        _gameViewModel = StateObject(wrappedValue: GameViewModel(contentStore: contentStore))
        #if DEBUG
        _configureViewModel = StateObject(wrappedValue: ConfigureViewModel(contentStore: contentStore))
        #endif
    }

    var body: some View {
        ZStack(alignment: .top) {
            PlayfulBackground()

            #if DEBUG
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

            #else
            GameView(viewModel: gameViewModel, contentStore: contentStore)
            #endif

            chrome
        }
        #if DEBUG
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .game {
                contentStore.reload()
                gameViewModel.attach(contentStore: contentStore)
            } else {
                configureViewModel.loadFromStore()
            }
        }
        #endif
        .alert(gameViewModel.t("annaUnavailableTitle"), isPresented: $gameViewModel.showAnnaUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(gameViewModel.t("annaUnavailableMessage"))
        }
    }

    private var chrome: some View {
        HStack(spacing: 8) {
            #if DEBUG
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

            #endif

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

            Menu {
                Link(gameViewModel.t("supportLink"), destination: URL(string: "https://spirea89.github.io/LanguageSpinApple/support.html")!)
                Link(gameViewModel.t("privacyLink"), destination: URL(string: "https://spirea89.github.io/LanguageSpinApple/privacy.html")!)
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 15, weight: .bold))
                    .glassChip()
            }
            .accessibilityLabel(gameViewModel.t("helpPrivacy"))

            #if DEBUG
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
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .tint(.white)
    }
}

#if DEBUG
private enum AppTab {
    case game
    case configure
}
#endif

#Preview {
    ContentView(contentStore: ContentStore())
}
