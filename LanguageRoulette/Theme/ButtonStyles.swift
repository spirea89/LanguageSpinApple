import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(disabled ? AppTheme.muted : (configuration.isPressed ? AppTheme.accentStrong : AppTheme.accent))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(configuration.isPressed ? AppTheme.line : AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.muted)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(configuration.isPressed ? AppTheme.line.opacity(0.5) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
