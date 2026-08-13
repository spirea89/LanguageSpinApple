import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.rounded(.title3, weight: .heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    colors: disabled
                        ? [AppTheme.muted, AppTheme.muted]
                        : [AppTheme.accent, Color(red: 1, green: 0.45, blue: 0.28)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: disabled ? .clear : AppTheme.accent.opacity(0.45), radius: 16, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
            .opacity(disabled ? 0.55 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.rounded(.headline, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(.white.opacity(configuration.isPressed ? 0.22 : 0.14))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.28), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var onDark = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.rounded(.subheadline, weight: .semibold))
            .foregroundStyle(onDark ? .white.opacity(0.88) : AppTheme.muted)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(configuration.isPressed ? (onDark ? .white.opacity(0.12) : AppTheme.line) : Color.clear)
            .clipShape(Capsule())
    }
}
