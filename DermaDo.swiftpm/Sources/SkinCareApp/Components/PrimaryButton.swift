import SwiftUI

// MARK: - PrimaryButton
/// Premium primary action button with subtle press animation.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appLabelLarge)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous)
                        .fill(isEnabled ? Color.appAccentPrimary : Color.appStone)
                )
        }
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(
            reduceMotion ? .none : .easeInOut(duration: 0.15),
            value: isPressed
        )
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
