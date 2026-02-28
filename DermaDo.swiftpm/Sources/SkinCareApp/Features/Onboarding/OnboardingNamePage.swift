import SwiftUI

/// Page 2: Collect the user's name with real-time validation.
struct OnboardingNamePage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSpacing.large) {
            Spacer()
            
            // Icon
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(DesignColors.roseGold)
                .padding(.bottom, DesignSpacing.small)
            
            // Title
            Text("What's your name?")
                .font(DesignTypography.headerEditorial)
                .foregroundColor(DesignColors.luminousPearl)
                .editorialTracking()
            
            // Subtitle
            Text("We'll personalize your skincare journey.")
                .font(DesignTypography.bodyUI)
                .foregroundColor(DesignColors.liquidSilver)
                .multilineTextAlignment(.center)
            
            // Text Field
            TextField("", text: $viewModel.userName, prompt:
                Text("Enter your name")
                    .foregroundColor(DesignColors.liquidSilver.opacity(0.5))
            )
            .font(DesignTypography.titleUI)
            .foregroundColor(DesignColors.luminousPearl)
            .multilineTextAlignment(.center)
            .padding(DesignSpacing.standard)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.element, style: .continuous)
                    .fill(DesignColors.voidAsh.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.element, style: .continuous)
                    .stroke(isNameFocused ? DesignColors.roseGold.opacity(0.5) : DesignColors.voidAsh.opacity(0.3), lineWidth: 1)
            )
            .focused($isNameFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .padding(.horizontal, DesignSpacing.large)
            .onSubmit { isNameFocused = false }
            
            // Validation hint
            if viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Name is required to continue")
                    .font(DesignTypography.captionUI)
                    .foregroundColor(DesignColors.roseGold.opacity(0.7))
            }
            
            Spacer()
            Spacer()
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { isNameFocused = false }
    }
}
