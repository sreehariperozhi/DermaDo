import SwiftUI
import AVFoundation

/// Page 5: Camera & Notification permissions + "Get Started" completion.
struct OnboardingPermissionsPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: DesignSpacing.large) {
            Spacer()
            
            // Icon
            Image(systemName: "shield.checkered")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(DesignColors.roseGold)
                .padding(.bottom, DesignSpacing.small)
            
            // Title
            Text("Almost There")
                .font(DesignTypography.headerEditorial)
                .foregroundColor(DesignColors.luminousPearl)
                .editorialTracking()
            
            Text("A few permissions to unlock the full experience.")
                .font(DesignTypography.bodyUI)
                .foregroundColor(DesignColors.liquidSilver)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSpacing.standard)
            
            // Permission Cards
            VStack(spacing: DesignSpacing.standard) {
                PermissionRow(
                    icon: "camera",
                    title: "Camera Access",
                    subtitle: "Capture your skin for AI-powered analysis.",
                    isGranted: viewModel.cameraPermissionGranted,
                    wasRequested: viewModel.cameraPermissionRequested,
                    action: { viewModel.requestCameraPermission() }
                )
                
                PermissionRow(
                    icon: "bell.badge",
                    title: "Notifications",
                    subtitle: "Gentle reminders for your skincare routine.",
                    isGranted: viewModel.notificationPermissionGranted,
                    wasRequested: viewModel.notificationPermissionRequested,
                    action: { viewModel.requestNotificationPermission() }
                )
            }
            .padding(.horizontal, DesignSpacing.large)
            
            Text("You can change these anytime in Settings.")
                .font(DesignTypography.captionUI)
                .foregroundColor(DesignColors.liquidSilver.opacity(0.5))
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Permission Row

private struct PermissionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isGranted: Bool
    let wasRequested: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSpacing.standard) {
            // Icon
            ZStack {
                Circle()
                    .fill(isGranted ? DesignColors.sageBotanical.opacity(0.15) : DesignColors.voidAsh)
                    .frame(width: 48, height: 48)
                
                Image(systemName: isGranted ? "checkmark" : icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isGranted ? DesignColors.sageBotanical : DesignColors.liquidSilver)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTypography.bodyStrongUI)
                    .foregroundColor(DesignColors.luminousPearl)
                
                Text(subtitle)
                    .font(DesignTypography.captionUI)
                    .foregroundColor(DesignColors.liquidSilver)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action
            if !isGranted {
                Button(action: action) {
                    Text(wasRequested ? "Denied" : "Allow")
                        .font(DesignTypography.captionUI)
                        .foregroundColor(wasRequested ? DesignColors.liquidSilver : DesignColors.roseGold)
                        .padding(.horizontal, DesignSpacing.standard)
                        .padding(.vertical, DesignSpacing.small)
                        .background(
                            Capsule()
                                .fill(wasRequested ? DesignColors.voidAsh : DesignColors.roseGold.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .disabled(wasRequested)
            }
        }
        .padding(DesignSpacing.standard)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.element, style: .continuous)
                .fill(DesignColors.voidCharcoal)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignRadius.element, style: .continuous)
                .stroke(DesignColors.voidAsh.opacity(0.5), lineWidth: 0.5)
        )
    }
}
