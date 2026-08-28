import SwiftUI

// MARK: - Motion tokens
// Single source of truth for animation timing. 150–300ms, springs and ease-outs.

enum Motion {
    /// Press feedback: fast in, springy out.
    static let press = Animation.spring(response: 0.18, dampingFraction: 0.6)
    /// Standard state change (likes, follows, tab content).
    static let standard = Animation.spring(response: 0.3, dampingFraction: 0.85)
    /// Larger movements (sheet interiors, list reflow).
    static let smooth = Animation.spring(response: 0.4, dampingFraction: 0.9)
    /// Simple fades.
    static let fade = Animation.easeOut(duration: 0.2)
}

// MARK: - Press feedback
// Every pressable scales to 0.97 with a spring return.

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

/// Primary action button: accent fill, rounded, scales on press.
struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor)
                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Card hover highlight
// macOS pointer affordance: cards lift subtly under the cursor.

struct HoverHighlight: ViewModifier {
    @State private var hovering = false
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.quaternary.opacity(hovering ? 0.4 : 0))
            )
            .animation(Motion.fade, value: hovering)
            .onHover { hovering = $0 }
    }
}

extension View {
    func hoverHighlight(cornerRadius: CGFloat = 12) -> some View {
        modifier(HoverHighlight(cornerRadius: cornerRadius))
    }
}

// MARK: - Heart burst
// Six particles radiate from the heart on like. 400ms, transform/opacity only.

struct HeartBurstView: View {
    /// Increment to fire the burst.
    let trigger: Int

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                BurstParticle(angle: Double(index) * 60 - 90, trigger: trigger)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct BurstParticle: View {
    let angle: Double
    let trigger: Int
    @State private var progress: CGFloat = 0

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 7))
            .foregroundStyle(.pink)
            .opacity(progress > 0 && progress < 1 ? 1.2 - progress : 0)
            .scaleEffect(0.5 + progress * 0.5)
            .offset(x: cos(angle * .pi / 180) * 20 * progress,
                    y: sin(angle * .pi / 180) * 20 * progress)
            .onChange(of: trigger) {
                progress = 0
                withAnimation(.easeOut(duration: 0.4)) {
                    progress = 1
                }
            }
    }
}

// MARK: - Custom empty states
// Content-shaped, inviting, one action. Never a bare default.

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)

            Text(title)
                .font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .onAppear {
            withAnimation(Motion.standard) { appeared = true }
        }
    }
}
