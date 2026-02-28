import SwiftUI

/// Page 4: Multi-select skin concerns with responsive wrapping grid.
struct OnboardingConcernsPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: DesignSpacing.small)]
    
    var body: some View {
        VStack(spacing: DesignSpacing.large) {
            Spacer()
            
            // Icon
            Image(systemName: "checklist")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(DesignColors.sageBotanical)
                .padding(.bottom, DesignSpacing.small)
            
            // Title
            Text("Skin Concerns")
                .font(DesignTypography.headerEditorial)
                .foregroundColor(DesignColors.luminousPearl)
                .editorialTracking()
            
            Text("Select all that apply. You can change these later.")
                .font(DesignTypography.bodyUI)
                .foregroundColor(DesignColors.liquidSilver)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSpacing.standard)
            
            // Multi-select Grid
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: DesignSpacing.small) {
                    ForEach(SkinConcern.allCases, id: \.self) { concern in
                        ConcernChip(
                            concern: concern,
                            isSelected: viewModel.selectedConcerns.contains(concern)
                        ) {
                            withAnimation(DesignMotion.tactilePress) {
                                if viewModel.selectedConcerns.contains(concern) {
                                    viewModel.selectedConcerns.remove(concern)
                                } else {
                                    viewModel.selectedConcerns.insert(concern)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSpacing.large)
            }
            .frame(maxHeight: 280)
            
            if viewModel.selectedConcerns.isEmpty {
                Text("Optional — skip if none apply")
                    .font(DesignTypography.captionUI)
                    .foregroundColor(DesignColors.liquidSilver.opacity(0.6))
            } else {
                Text("\(viewModel.selectedConcerns.count) selected")
                    .font(DesignTypography.captionUI)
                    .foregroundColor(DesignColors.roseGold)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Concern Chip

private struct ConcernChip: View {
    let concern: SkinConcern
    let isSelected: Bool
    let action: () -> Void
    
    private var label: String {
        switch concern {
        case .acne: return "Acne"
        case .aging: return "Aging"
        case .darkSpots: return "Dark Spots"
        case .dryness: return "Dryness"
        case .dullness: return "Dull Skin"
        case .largePores: return "Large Pores"
        case .redness: return "Redness"
        case .sensitivity: return "Sensitivity"
        case .unEvenTexture: return "Texture"
        case .wrinkles: return "Wrinkles"
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DesignTypography.captionUI)
                .foregroundColor(isSelected ? DesignColors.luminousPearl : DesignColors.liquidSilver)
                .padding(.horizontal, DesignSpacing.standard)
                .padding(.vertical, DesignSpacing.small)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: DesignRadius.control, style: .continuous)
                        .fill(isSelected ? DesignColors.roseGold.opacity(0.15) : DesignColors.voidAsh.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignRadius.control, style: .continuous)
                        .stroke(isSelected ? DesignColors.roseGold.opacity(0.4) : Color.clear, lineWidth: 1)
                )
                .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
