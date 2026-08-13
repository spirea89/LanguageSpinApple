import SwiftUI

enum AppTheme {
    static let ink = Color(red: 0x17 / 255, green: 0x14 / 255, blue: 0x2c / 255)
    static let muted = Color(red: 0x6b / 255, green: 0x64 / 255, blue: 0x86 / 255)
    static let line = Color.white.opacity(0.18)
    static let cardLine = Color(red: 0xd8 / 255, green: 0xd0 / 255, blue: 0xea / 255)
    static let paper = Color(red: 0x2a / 255, green: 0x0f / 255, blue: 0x4e / 255)
    static let surface = Color.white
    static let accent = Color(red: 0xff / 255, green: 0x3d / 255, blue: 0x6e / 255)
    static let accentStrong = Color(red: 0xe0 / 255, green: 0x1e / 255, blue: 0x58 / 255)
    static let gold = Color(red: 0xff / 255, green: 0xc4 / 255, blue: 0x3a / 255)
    static let green = Color(red: 0x22 / 255, green: 0xd1 / 255, blue: 0x7a / 255)
    static let blue = Color(red: 0x3d / 255, green: 0x8b / 255, blue: 0xff / 255)
    static let violet = Color(red: 0x7a / 255, green: 0x3d / 255, blue: 0xff / 255)

    static let wheelColors: [Color] = [
        Color(red: 0xff / 255, green: 0xc4 / 255, blue: 0x3a / 255),
        Color(red: 0xff / 255, green: 0x3d / 255, blue: 0x6e / 255),
        Color(red: 0x3d / 255, green: 0x8b / 255, blue: 0xff / 255),
        Color(red: 0x22 / 255, green: 0xd1 / 255, blue: 0x7a / 255),
        Color(red: 0xb4 / 255, green: 0x4b / 255, blue: 0xff / 255),
        Color(red: 0xff / 255, green: 0x7a / 255, blue: 0x2e / 255)
    ]

    static let scoreColors: [Color] = [
        Color(red: 0x8b / 255, green: 0x86 / 255, blue: 0xa3 / 255),
        Color(red: 0x3d / 255, green: 0x8b / 255, blue: 0xff / 255),
        Color(red: 0x22 / 255, green: 0xd1 / 255, blue: 0x7a / 255),
        Color(red: 0xff / 255, green: 0xc4 / 255, blue: 0x3a / 255)
    ]

    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    static func playerColor(_ index: Int) -> Color {
        wheelColors[index % wheelColors.count]
    }
}

struct PlayfulBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.05, blue: 0.38),
                    Color(red: 0.36, green: 0.08, blue: 0.58),
                    Color(red: 0.52, green: 0.10, blue: 0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.gold.opacity(0.32))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: 150, y: -220)

            Circle()
                .fill(AppTheme.accent.opacity(0.38))
                .frame(width: 240, height: 240)
                .blur(radius: 55)
                .offset(x: -160, y: 280)

            Circle()
                .fill(AppTheme.blue.opacity(0.30))
                .frame(width: 210, height: 210)
                .blur(radius: 45)
                .offset(x: 90, y: 430)
        }
        .ignoresSafeArea()
    }
}

struct GlassChip: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.rounded(.caption, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.16))
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

extension View {
    func glassChip() -> some View {
        modifier(GlassChip())
    }
}
