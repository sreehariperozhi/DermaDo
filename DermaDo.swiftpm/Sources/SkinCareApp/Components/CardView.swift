import SwiftUI

// MARK: - CardView
/// Premium card component with adaptive styling.
/// Ultra-subtle shadow in light mode, no shadow in dark mode.
/// Subtle scale animation on tap. Respects Reduce Motion.
struct CardView<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.cardPadding)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLarge, style: .continuous))
            .shadow(
                color: colorScheme == .light ? Color.appShadow : .clear,
                radius: AppSpacing.shadowRadius,
                x: AppSpacing.shadowOffset.width,
                y: AppSpacing.shadowOffset.height
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 0.2),
                value: isPressed
            )
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}
