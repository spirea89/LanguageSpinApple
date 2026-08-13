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
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(AppTheme.wheelColors[index % AppTheme.wheelColors.count])
                    .frame(width: 14, height: 14)
                    .offset(y: burst ? -160 - CGFloat(index * 12) : 0)
                    .offset(x: CGFloat(index - 4) * 28)
                    .opacity(burst ? 0 : 1)
                    .animation(.easeOut(duration: 1.15).delay(Double(index) * 0.06), value: burst)
            }

            VStack(spacing: 14) {
                Text("🏆")
                    .font(.system(size: 54))
                    .scaleEffect(burst ? 1 : 0.4)
                    .animation(.spring(response: 0.45, dampingFraction: 0.55), value: burst)

                Text(eyebrow.uppercased())
                    .font(AppTheme.rounded(.caption, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.gold)

                Text(winners)
                    .font(AppTheme.rounded(.title, weight: .black))
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
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: AppTheme.gold.opacity(0.35), radius: 30, y: 12)
            .padding(24)
            .colorScheme(.light)
        }
        .onAppear { burst = true }
        .accessibilityAddTraits(.isModal)
    }
}
