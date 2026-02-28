import SwiftUI

/// Page 3: Select skin type with single-selection grid.
struct OnboardingSkinTypePage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: DesignSpacing.standard)]
    
    var body: some View {
        VStack(spacing: DesignSpacing.large) {
            Spacer()
            
            // Icon
            Image(systemName: "drop.halffull")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(DesignColors.ceruleanHydration)
                .padding(.bottom, DesignSpacing.small)
            
            // Title
            Text("Your Skin Type")
                .font(DesignTypography.headerEditorial)
                .foregroundColor(DesignColors.luminousPearl)
                .editorialTracking()
            
            Text("Select the one that best describes your skin.")
                .font(DesignTypography.bodyUI)
                .foregroundColor(DesignColors.liquidSilver)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSpacing.standard)
            
            // Grid
            LazyVGrid(columns: columns, spacing: DesignSpacing.standard) {
                ForEach(SkinType.allCases, id: \.self) { skinType in
                    SkinTypeCard(
                        skinType: skinType,
                        isSelected: viewModel.selectedSkinType == skinType
                    ) {
                        withAnimation(DesignMotion.tactilePress) {
                            viewModel.selectedSkinType = skinType
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSpacing.large)
            
            if viewModel.selectedSkinType == nil {
                Text("Please select your skin type")
                    .font(DesignTypography.captionUI)
                    .foregroundColor(DesignColors.roseGold.opacity(0.7))
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Skin Type Card

private struct SkinTypeCard: View {
    let skinType: SkinType
    let isSelected: Bool
    let action: () -> Void
    
    private var icon: String {
        switch skinType {
        case .oily: return "humidity.fill"
        case .dry: return "sun.dust"
        case .combination: return "circle.lefthalf.filled"
        case .sensitive: return "leaf"
        case .normal: return "sparkles"
        }
    }
    
    private var label: String {
        skinType.rawValue.capitalized
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSpacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(isSelected ? DesignColors.roseGold : DesignColors.liquidSilver)
                
                Text(label)
                    .font(DesignTypography.bodyStrongUI)
                    .foregroundColor(isSelected ? DesignColors.luminousPearl : DesignColors.liquidSilver)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.element, style: .continuous)
                    .fill(isSelected ? DesignColors.roseGold.opacity(0.12) : DesignColors.voidAsh.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.element, style: .continuous)
                    .stroke(isSelected ? DesignColors.roseGold.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
