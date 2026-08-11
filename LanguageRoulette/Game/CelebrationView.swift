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
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(AppTheme.wheelColors[index % AppTheme.wheelColors.count].opacity(0.85))
                    .frame(width: 12, height: 12)
                    .offset(y: burst ? -140 - CGFloat(index * 18) : 0)
                    .offset(x: CGFloat(index - 2) * 36)
                    .opacity(burst ? 0 : 1)
                    .animation(.easeOut(duration: 1.2).delay(Double(index) * 0.08), value: burst)
            }

            VStack(spacing: 14) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.muted)

                Text(winners)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.ink)

                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.muted)

                Button(closeTitle, action: onClose)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(28)
            .frame(maxWidth: 360)
            .background(AppTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppTheme.ink.opacity(0.18), radius: 24, y: 12)
            .padding(24)
        }
        .onAppear { burst = true }
        .accessibilityAddTraits(.isModal)
    }
}
