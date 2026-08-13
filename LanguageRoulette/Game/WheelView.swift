import SwiftUI

struct WheelView: View {
    let categories: [Category]
    let languageCode: String
    let fallbackLanguage: String
    let rotation: Double
    let isSpinning: Bool
    var canSpin: Bool = false
    var onSpin: (() -> Void)? = nil

    @State private var dragOffset: Double = 0
    @State private var lastDragAngle: Double?
    @State private var dragTravel: Double = 0

    private var displayedRotation: Double {
        rotation + dragOffset
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.gold.opacity(0.55), AppTheme.accent.opacity(0.18), .clear],
                            center: .center,
                            startRadius: size * 0.42,
                            endRadius: size * 0.62
                        )
                    )
                    .frame(width: size, height: size)
                    .scaleEffect(1.16)

                ZStack {
                    Circle()
                        .fill(AppTheme.surface)
                        .shadow(color: AppTheme.accent.opacity(0.35), radius: 22, y: 10)

                    if categories.isEmpty {
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [AppTheme.gold, AppTheme.accent, AppTheme.blue, AppTheme.green, AppTheme.gold],
                                    center: .center
                                )
                            )
                    } else {
                        WheelSegments(categories: categories)
                        WheelLabels(
                            categories: categories,
                            languageCode: languageCode,
                            fallbackLanguage: fallbackLanguage,
                            rotation: displayedRotation
                        )
                    }

                    Circle()
                        .stroke(.white.opacity(0.35), lineWidth: 5)
                        .padding(3)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.gold, AppTheme.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.12, height: size * 0.12)
                        .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 2))
                }
                .frame(width: size, height: size)
                .rotationEffect(.degrees(displayedRotation))
                .animation(isSpinning ? .easeOut(duration: 4.9) : .interactiveSpring(response: 0.2, dampingFraction: 0.85), value: displayedRotation)
                .gesture(spinGesture(center: center))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Pointer()
                .frame(width: 24, height: 30)
                .position(x: geo.size.width / 2, y: (geo.size.height - size) / 2 + 6)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spinning category wheel")
        .accessibilityHint("Swipe the wheel to spin")
        .accessibilityAddTraits(canSpin ? .isButton : [])
        .accessibilityAction(named: Text("Spin")) {
            guard canSpin else { return }
            onSpin?()
        }
        .onChange(of: isSpinning) { _, spinning in
            if spinning {
                dragOffset = 0
                lastDragAngle = nil
                dragTravel = 0
            }
        }
    }

    private func spinGesture(center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard canSpin, !isSpinning else { return }
                let angle = atan2(value.location.y - center.y, value.location.x - center.x) * 180 / .pi
                if let lastDragAngle {
                    var delta = angle - lastDragAngle
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }
                    dragOffset += delta
                    dragTravel += abs(delta)
                }
                lastDragAngle = angle
            }
            .onEnded { _ in
                defer {
                    lastDragAngle = nil
                    dragTravel = 0
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragOffset = 0
                    }
                }
                guard canSpin, !isSpinning else { return }
                if dragTravel > 25 {
                    onSpin?()
                }
            }
    }
}

private struct WheelSegments: View {
    let categories: [Category]

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let step = (2 * Double.pi) / Double(categories.count)

            for index in categories.indices {
                let start = Angle(radians: -Double.pi / 2 + Double(index) * step)
                let end = Angle(radians: -Double.pi / 2 + Double(index + 1) * step)
                var path = Path()
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
                path.closeSubpath()
                context.fill(path, with: .color(AppTheme.wheelColors[index % AppTheme.wheelColors.count]))
            }
        }
    }
}

private struct WheelLabels: View {
    let categories: [Category]
    let languageCode: String
    let fallbackLanguage: String
    let rotation: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let step = 360.0 / Double(categories.count)
            let wheelAngle = normalize(rotation)
            let shouldFlip = wheelAngle > 90 && wheelAngle < 270

            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                let angle = Double(index) * step + step / 2
                let labelAngle = (angle - 90) * .pi / 180
                let radius = size * 0.33
                let x = size / 2 + cos(labelAngle) * radius
                let y = size / 2 + sin(labelAngle) * radius

                Text(category.label(for: languageCode, fallback: fallbackLanguage))
                    .font(.system(size: max(9, size * 0.034), weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                    .rotationEffect(.degrees(shouldFlip ? 180 : 0))
                    .position(x: x, y: y)
            }
        }
    }

    private func normalize(_ value: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: 360)
        return result >= 0 ? result : result + 360
    }
}

private struct Pointer: View {
    var body: some View {
            Triangle()
                .fill(AppTheme.gold)
                .overlay(
                    Triangle()
                        .stroke(.white, lineWidth: 1.5)
                )
                .shadow(color: AppTheme.gold.opacity(0.6), radius: 6)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
