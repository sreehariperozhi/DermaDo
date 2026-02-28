import SwiftUI

struct ProfileDetailView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // MARK: - Background Layer
            DesignColors.voidObsidian.ignoresSafeArea()
            
            Circle()
                .fill(DesignColors.ceruleanHydration.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: -150, y: -250)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DesignSpacing.large) {
                    
                    // MARK: - Navigation Header (Custom)
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(DesignColors.liquidSilver)
                        }
                        .padding(.trailing, DesignSpacing.small)
                        
                        Text("Profile")
                            .font(DesignTypography.titleUI)
                            .foregroundColor(DesignColors.luminousPearl)
                        
                        Spacer()
                    }
                    .padding(.bottom, DesignSpacing.standard)
                    
                    // MARK: - Form Sections
                    VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                        sectionLabel("Personal Info")
                        
                        VStack(spacing: 0) {
                            TextField("Your Name", text: $viewModel.userName)
                                .font(DesignTypography.bodyUI)
                                .foregroundColor(DesignColors.luminousPearl)
                                .padding(DesignSpacing.medium)
                        }
                        .glassCard()
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                        sectionLabel("Skin Type")
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Selected Type")
                                    .font(DesignTypography.bodyUI)
                                    .foregroundColor(DesignColors.luminousPearl)
                                
                                Spacer()
                                
                                Picker("Skin Type", selection: $viewModel.selectedSkinType) {
                                    ForEach(SkinType.allCases, id: \.self) { type in
                                        Text(type.rawValue.capitalized).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(DesignColors.roseGold)
                            }
                            .padding(DesignSpacing.medium)
                        }
                        .glassCard()
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                        sectionLabel("Skin Goals")
                        
                        VStack(spacing: 0) {
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
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                    }
                                    .padding(DesignSpacing.medium)
                                }
                                .buttonStyle(.plain)
                                
                                if goal != SkinGoal.allCases.last {
                                    Divider().background(DesignColors.voidAsh.opacity(0.3)).padding(.horizontal, DesignSpacing.medium)
                                }
                            }
                        }
                        .glassCard()
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, DesignSpacing.large)
                .padding(.top, DesignSpacing.standard)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Helpers
    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(DesignTypography.microUI)
            .captionTracking()
            .foregroundColor(DesignColors.liquidSilver)
            .padding(.leading, 4)
    }
}
