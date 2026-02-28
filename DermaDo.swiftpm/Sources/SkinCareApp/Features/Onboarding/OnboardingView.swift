import SwiftUI

/// The root onboarding container — manages page navigation, progress, and completion.
struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted = false
    @State private var completionAnimation = false
    
    init(userManager: UserManagerProtocol, notificationManager: NotificationManagerProtocol) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            userManager: userManager,
            notificationManager: notificationManager
        ))
    }
    
    var body: some View {
        ZStack {
            // Background
            DesignColors.voidObsidian
                .ignoresSafeArea()
            
            // Ambient orb
            Circle()
                .fill(DesignColors.roseGold.opacity(0.04))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(y: -150)
            
            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $viewModel.currentPage) {
                    OnboardingWelcomePage()
                        .tag(0)
                    
                    OnboardingNamePage(viewModel: viewModel)
                        .tag(1)
                    
                    OnboardingSkinTypePage(viewModel: viewModel)
                        .tag(2)
                    
                    OnboardingConcernsPage(viewModel: viewModel)
                        .tag(3)
                    
                    OnboardingPermissionsPage(viewModel: viewModel)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignMotion.editorialSpring, value: viewModel.currentPage)
                
                // Bottom Control Bar
                bottomBar
                    .padding(.horizontal, DesignSpacing.large)
                    .padding(.bottom, DesignSpacing.medium)
            }
        }
        .opacity(completionAnimation ? 0 : 1)
        .scaleEffect(completionAnimation ? 1.05 : 1.0)
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        VStack(spacing: DesignSpacing.standard) {
            // Progress Dots
            HStack(spacing: DesignSpacing.small) {
                ForEach(0..<OnboardingViewModel.totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index <= viewModel.currentPage ? DesignColors.roseGold : DesignColors.voidAsh)
                        .frame(width: index == viewModel.currentPage ? 24 : 8, height: 8)
                        .animation(DesignMotion.tactilePress, value: viewModel.currentPage)
                }
            }
            
            // Buttons
            HStack(spacing: DesignSpacing.standard) {
                // Back Button
                if viewModel.currentPage > 0 {
                    Button(action: { viewModel.goBack() }) {
                        HStack(spacing: DesignSpacing.micro) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(DesignTypography.bodyStrongUI)
                        }
                        .foregroundColor(DesignColors.liquidSilver)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSpacing.standard)
                        .background(
                            RoundedRectangle(cornerRadius: DesignRadius.element, style: .continuous)
                                .fill(DesignColors.voidAsh.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
                
                // Next / Get Started Button
                Button(action: {
                    if viewModel.isLastPage {
                        completeOnboarding()
                    } else {
                        viewModel.advance()
                    }
                }) {
                    HStack(spacing: DesignSpacing.micro) {
                        Text(viewModel.isLastPage ? "Get Started" : "Next")
                            .font(DesignTypography.bodyStrongUI)
                        
                        if !viewModel.isLastPage {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(viewModel.canAdvance ? DesignColors.luminousPearl : DesignColors.liquidSilver.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSpacing.standard)
                    .background(
                        RoundedRectangle(cornerRadius: DesignRadius.element, style: .continuous)
                            .fill(viewModel.canAdvance
                                  ? DesignColors.roseGold
                                  : DesignColors.voidAsh.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canAdvance)
            }
            .animation(DesignMotion.editorialSpring, value: viewModel.currentPage)
        }
    }
    
    // MARK: - Completion
    
    private func completeOnboarding() {
        viewModel.completeOnboarding()
        
        withAnimation(DesignMotion.editorialSpring) {
            completionAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isOnboardingCompleted = true
        }
    }
}
