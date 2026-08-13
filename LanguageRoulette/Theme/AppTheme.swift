import SwiftUI

enum AppTheme {
    static let ink = Color(red: 0x2A / 255, green: 0x1A / 255, blue: 0x4A / 255)
    static let muted = Color(red: 0x6B / 255, green: 0x4E / 255, blue: 0x8A / 255)
    static let line = Color(red: 0xFF / 255, green: 0xD6 / 255, blue: 0xEC / 255)
    static let paper = Color(red: 0xFF / 255, green: 0xF6 / 255, blue: 0xFB / 255)
    static let sky = Color(red: 0xC9 / 255, green: 0xF0 / 255, blue: 0xFF / 255)
    static let mint = Color(red: 0xC8 / 255, green: 0xFB / 255, blue: 0xD7 / 255)
    static let lemon = Color(red: 0xFF / 255, green: 0xF3 / 255, blue: 0xA8 / 255)
    static let peach = Color(red: 0xFF / 255, green: 0xD8 / 255, blue: 0xB8 / 255)
    static let surface = Color.white
    static let accent = Color(red: 0xFF / 255, green: 0x5C / 255, blue: 0x8A / 255)
    static let accentStrong = Color(red: 0xE2 / 255, green: 0x2B / 255, blue: 0x6A / 255)
    static let gold = Color(red: 0xFF / 255, green: 0xC4 / 255, blue: 0x3A / 255)
    static let green = Color(red: 0x2F / 255, green: 0xC4 / 255, blue: 0x7C / 255)
    static let blue = Color(red: 0x4D / 255, green: 0x9F / 255, blue: 0xFF / 255)
    static let purple = Color(red: 0x9B / 255, green: 0x6B / 255, blue: 0xFF / 255)

    static let wheelColors: [Color] = [
        Color(red: 0xFF / 255, green: 0x6B / 255, blue: 0x9D / 255),
        Color(red: 0xFF / 255, green: 0xC4 / 255, blue: 0x3A / 255),
        Color(red: 0x4D / 255, green: 0x9F / 255, blue: 0xFF / 255),
        Color(red: 0x2F / 255, green: 0xC4 / 255, blue: 0x7C / 255),
        Color(red: 0x9B / 255, green: 0x6B / 255, blue: 0xFF / 255),
        Color(red: 0xFF / 255, green: 0x8A / 255, blue: 0x4C / 255),
        Color(red: 0x5C / 255, green: 0xE1 / 255, blue: 0xE6 / 255),
        Color(red: 0xFF / 255, green: 0x5C / 255, blue: 0x8A / 255)
    ]

    static let playerEmojis = ["🦊", "🐼", "🐸", "🦄", "🐯", "🐧", "🐰", "🐻", "🦋", "🐙"]
    static let scoreEmojis = [0: "💤", 10: "⭐", 30: "🎉", 45: "🏆"]
    static let scoreColors: [Int: Color] = [
        0: muted.opacity(0.85),
        10: blue,
        30: green,
        45: gold
    ]

    static func playerEmoji(at index: Int) -> String {
        playerEmojis[index % playerEmojis.count]
    }

    static func playerColor(at index: Int) -> Color {
        wheelColors[index % wheelColors.count]
    }

    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

struct PlayfulBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.sky, AppTheme.paper, AppTheme.peach.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.lemon.opacity(0.55))
                .frame(width: 220, height: 220)
                .offset(x: 150, y: -220)

            Circle()
                .fill(AppTheme.mint.opacity(0.5))
                .frame(width: 180, height: 180)
                .offset(x: -160, y: 80)

            Circle()
                .fill(AppTheme.accent.opacity(0.16))
                .frame(width: 140, height: 140)
                .offset(x: 40, y: 280)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
