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
                disabled
                    ? AppTheme.muted.opacity(0.45)
                    : (configuration.isPressed ? AppTheme.accentStrong : AppTheme.accent)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: disabled ? .clear : AppTheme.accent.opacity(0.35), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed && !disabled ? 0.97 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.rounded(.headline, weight: .bold))
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(configuration.isPressed ? AppTheme.lemon : AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.line, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.rounded(.subheadline, weight: .bold))
            .foregroundStyle(AppTheme.muted)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(configuration.isPressed ? AppTheme.line.opacity(0.6) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct KidChipStyle: ButtonStyle {
    var selected: Bool
    var color: Color = AppTheme.purple

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.rounded(.headline, weight: .heavy))
            .foregroundStyle(selected ? .white : AppTheme.ink)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(selected ? color : AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? color : AppTheme.line, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: selected ? color.opacity(0.28) : .clear, radius: 6, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
