import SwiftUI

struct NotificationsView: View {
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
                    
                    // MARK: - Navigation Header
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(DesignColors.liquidSilver)
                        }
                        .padding(.trailing, DesignSpacing.small)
                        
                        Text("Notifications")
                            .font(DesignTypography.titleUI)
                            .foregroundColor(DesignColors.luminousPearl)
                        
                        Spacer()
                    }
                    .padding(.bottom, DesignSpacing.standard)
                    
                    // MARK: - Toggle Section
                    VStack(spacing: 0) {
                        Toggle(isOn: $viewModel.notificationsEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Reminders")
                                    .font(DesignTypography.bodyStrongUI)
                                    .foregroundColor(DesignColors.luminousPearl)
                                Text("Master control for routine alerts")
                                    .font(DesignTypography.captionUI)
                                    .foregroundColor(DesignColors.liquidSilver)
                            }
                        }
                        .tint(DesignColors.roseGold)
                        .padding(DesignSpacing.medium)
                    }
                    .glassCard()
                    
                    // MARK: - Time Pickers
                    if viewModel.notificationsEnabled {
                        VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                            sectionLabel("Routine Times")
                            
                            VStack(spacing: 0) {
                                DatePicker("Morning Routine", selection: $viewModel.morningReminderTime, displayedComponents: .hourAndMinute)
                                    .font(DesignTypography.bodyUI)
                                    .foregroundColor(DesignColors.luminousPearl)
                                    .padding(DesignSpacing.medium)
                                
                                Divider().background(DesignColors.voidAsh.opacity(0.3)).padding(.horizontal, DesignSpacing.medium)
                                
                                DatePicker("Evening Routine", selection: $viewModel.eveningReminderTime, displayedComponents: .hourAndMinute)
                                    .font(DesignTypography.bodyUI)
                                    .foregroundColor(DesignColors.luminousPearl)
                                    .padding(DesignSpacing.medium)
                            }
                            .glassCard()
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
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
