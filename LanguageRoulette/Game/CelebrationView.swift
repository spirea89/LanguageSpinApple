import SwiftUI

struct CelebrationView: View {
    let eyebrow: String
    let winners: String
    let subtitle: String
    let closeTitle: String
    let onClose: () -> Void

    @State private var burst = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            ForEach(0..<8, id: \.self) { index in
                Text(["🎉", "⭐", "🎈", "🌈", "🏆"][index % 5])
                    .font(.title)
                    .offset(y: burst ? -160 - CGFloat(index * 14) : 20)
                    .offset(x: CGFloat(index - 4) * 28)
                    .opacity(burst ? 0 : 1)
                    .animation(.easeOut(duration: 1.15).delay(Double(index) * 0.06), value: burst)
            }

            VStack(spacing: 14) {
                Text("🏆")
                    .font(.system(size: 64))
                    .scaleEffect(burst ? 1.08 : 0.9)

                Text(eyebrow)
                    .font(AppTheme.rounded(.caption, weight: .heavy))
                    .foregroundStyle(AppTheme.purple)

                Text(winners)
                    .font(AppTheme.rounded(.title, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.ink)

                Text(subtitle)
                    .font(AppTheme.rounded(.body, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.muted)

                Button(closeTitle, action: onClose)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(28)
            .frame(maxWidth: 360)
            .background(AppTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: AppTheme.accent.opacity(0.22), radius: 24, y: 12)
            .padding(24)
        }
        .onAppear { burst = true }
        .accessibilityAddTraits(.isModal)
    }
}
