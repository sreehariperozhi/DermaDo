import SwiftUI

// MARK: - Dedicated Settings Profile Section
struct SettingsProfileSection: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.medium) {
            sectionLabel("Personal Profile")
            
            VStack(spacing: DesignSpacing.medium) {
                // Name Input
                VStack(alignment: .leading, spacing: DesignSpacing.micro) {
                    Text("Name")
                        .font(DesignTypography.captionUI)
                        .foregroundColor(DesignColors.liquidSilver)
                    
                    TextField("Your Name", text: $viewModel.userName)
                        .font(DesignTypography.bodyUI)
                        .foregroundColor(DesignColors.luminousPearl)
                        .padding(.vertical, DesignSpacing.small)
                        .padding(.horizontal, DesignSpacing.medium)
                        .background(DesignColors.voidAsh.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.element))
                }
                
                Divider().background(DesignColors.voidAsh.opacity(0.3))
                
                // Skin Type Picker
                VStack(alignment: .leading, spacing: DesignSpacing.micro) {
                    Text("Skin Type")
                        .font(DesignTypography.captionUI)
                        .foregroundColor(DesignColors.liquidSilver)
                    
                    Picker("Skin Type", selection: $viewModel.selectedSkinType) {
                        ForEach(SkinType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DesignColors.roseGold)
                }
                
                Divider().background(DesignColors.voidAsh.opacity(0.3))
                
                // Skin Goals Multi-Select
                VStack(alignment: .leading, spacing: DesignSpacing.micro) {
                    Text("Skin Goals")
                        .font(DesignTypography.captionUI)
                        .foregroundColor(DesignColors.liquidSilver)
                    
                    ForEach(SkinGoal.allCases, id: \.self) { goal in
                        Button(action: { viewModel.toggleSkinGoal(goal) }) {
                            HStack {
                                Text(goal.rawValue)
                                    .font(DesignTypography.bodyUI)
                                    .foregroundColor(DesignColors.luminousPearl)
                                
                                Spacer()
                                
                                if viewModel.selectedSkinGoals.contains(goal) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignColors.roseGold)
                                }
                            }
                            .padding(.vertical, DesignSpacing.micro)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(DesignSpacing.medium)
            .glassCard()
        }
    }
    
    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(DesignTypography.microUI)
            .captionTracking()
            .foregroundColor(DesignColors.liquidSilver)
            .padding(.leading, 4)
    }
}
