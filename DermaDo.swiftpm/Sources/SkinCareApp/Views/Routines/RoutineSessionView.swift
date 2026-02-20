import SwiftUI
import Combine

// MARK: - RoutineSessionView
/// A guided session view for performing a skincare routine.
/// Displays timers, product details, and steps.
struct RoutineSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: RoutineSessionViewModel

    init(routine: Routine, productManager: ProductManagerProtocol) {
        _viewModel = StateObject(wrappedValue: RoutineSessionViewModel(routine: routine, productManager: productManager))
    }

    var body: some View {
        ZStack {
            Color.appBackgroundPrimary.ignoresSafeArea()

            VStack {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.appCardBackground)
                            )
                    }
                    Spacer()
                    Text("Routine Session")
                        .font(.appHeading3)
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.sm)

                // Progress Bar
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .appAccentPrimary))
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.xs)

                Spacer()

                // Step Content
                if let step = viewModel.currentStep {
                    VStack(spacing: AppSpacing.xl) {
                        // Product Image
                        if let image = viewModel.currentProductImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.appAccentSubtle, lineWidth: 3)
                                )
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.appCardBackground)
                                    .frame(width: 110, height: 110)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.appAccentSubtle, lineWidth: 3)
                                    )

                                Image(systemName: step.stepType == .cleanse ? "drop" : "sparkles")
                                    .font(.system(size: 40))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.appAccentPrimary)
                            }
                        }

                        // Product Name & Instruction
                        VStack(spacing: AppSpacing.xs) {
                            Text(viewModel.currentProduct?.name ?? step.stepType.rawValue.capitalized)
                                .font(.appSectionTitle)
                                .foregroundColor(.appTextPrimary)
                                .multilineTextAlignment(.center)

                            if let brand = viewModel.currentProduct?.brand, !brand.isEmpty {
                                Text(brand)
                                    .font(.appBody)
                                    .foregroundColor(.appTextSecondary)
                            }

                            Text(step.instruction.isEmpty ? "Follow the product instructions." : step.instruction)
                                .font(.appBody)
                                .foregroundColor(.appTextPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.top, AppSpacing.xxs)
                                .padding(.horizontal, AppSpacing.screenHorizontal)
                        }

                        // Timer Display
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 8.0)
                                .foregroundColor(Color.appAccentSubtle)
                                .frame(width: 150, height: 150)

                            Circle()
                                .trim(from: 0.0, to: CGFloat(min(viewModel.timeRemaining / Double(step.durationSeconds ?? 60), 1.0)))
                                .stroke(style: StrokeStyle(lineWidth: 8.0, lineCap: .round, lineJoin: .round))
                                .foregroundColor(Color.appAccentPrimary)
                                .rotationEffect(Angle(degrees: 270.0))
                                .animation(.linear, value: viewModel.timeRemaining)
                                .frame(width: 150, height: 150)

                            Text(String(format: "%02d:%02d", Int(viewModel.timeRemaining) / 60, Int(viewModel.timeRemaining) % 60))
                                .font(.system(size: 36, weight: .semibold, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                } else {
                    // Session Completed View
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.appSuccess)

                        Text("Routine Complete")
                            .font(.appLargeTitle)
                            .foregroundColor(.appTextPrimary)

                        Text("Great job keeping up with your skincare routine.")
                            .font(.appBody)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xxl)
                    }
                }

                Spacer()

                // Controls
                if !viewModel.sessionComplete {
                    HStack(spacing: AppSpacing.xxxl) {
                        Button(action: { viewModel.previousStep() }) {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                                .foregroundColor(viewModel.currentStepIndex > 0 ? .appTextPrimary : .appTextTertiary.opacity(0.3))
                        }
                        .disabled(viewModel.currentStepIndex == 0)

                        Button(action: { viewModel.toggleTimer() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.appAccentPrimary)
                                    .frame(width: 64, height: 64)

                                Image(systemName: viewModel.isTimerActive ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }

                        Button(action: { viewModel.nextStep() }) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                    .padding(.bottom, AppSpacing.xxxl)
                } else {
                    PrimaryButton(
                        title: "Done",
                        action: { presentationMode.wrappedValue.dismiss() }
                    )
                    .padding(.horizontal, AppSpacing.xxxl)
                    .padding(.bottom, AppSpacing.xxxl)
                }
            }
        }
    }
}
