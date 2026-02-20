import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject var dependencies: AppDependencies

    var body: some View {
        RoutinesViewContent(viewModel: RoutinesViewModel(routineManager: dependencies.routineManager))
    }
}

// MARK: - RoutinesViewContent

struct RoutinesViewContent: View {
    @StateObject var viewModel: RoutinesViewModel
    @State private var showingAddRoutine = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundPrimary.ignoresSafeArea()

                if viewModel.routines.isEmpty {
                    // Empty State
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 40))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.appTextTertiary)

                        Text("No Routines Yet")
                            .font(.appSectionTitle)
                            .foregroundColor(.appTextPrimary)

                        Text("Create a routine to start tracking your skincare journey.")
                            .font(.appBody)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xxl)

                        Button(action: { showingAddRoutine = true }) {
                            Text("Create Routine")
                                .font(.appLabelLarge)
                                .foregroundColor(.white)
                                .padding(.horizontal, AppSpacing.xl)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: AppSpacing.radiusSmall, style: .continuous)
                                        .fill(Color.appAccentPrimary)
                                )
                        }
                        .padding(.top, AppSpacing.xs)
                    }
                    .opacity(appeared ? 1 : 0)
                } else {
                    List {
                        ForEach(viewModel.routines) { routine in
                            RoutineRow(routine: routine, onToggle: {
                                viewModel.toggleRoutine(routine)
                            })
                            .background(
                                NavigationLink("", destination: RoutineDetailView(viewModel: RoutineDetailViewModel(routineManager: viewModel.routineManager, mode: .edit(routine))))
                                    .opacity(0)
                            )
                            .listRowBackground(Color.appCardBackground)
                            .listRowSeparatorTint(Color.appDivider)
                        }
                        .onDelete(perform: viewModel.deleteRoutine)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .opacity(appeared ? 1 : 0)
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRoutine = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.appAccentPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddRoutine) {
                RoutineDetailView(viewModel: RoutineDetailViewModel(routineManager: viewModel.routineManager, mode: .add))
            }
            .onAppear {
                viewModel.refresh()
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appeared = true
                    }
                } else {
                    appeared = true
                }
            }
        }
    }
}

// MARK: - RoutineRow

struct RoutineRow: View {
    let routine: Routine
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(.appHeading3)
                    .foregroundColor(routine.isEnabled ? .appTextPrimary : .appTextTertiary)

                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: routine.timeOfDay == .morning ? "sun.max" : routine.timeOfDay == .evening ? "moon.stars" : "clock")
                        .font(.system(size: 12))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.appAccentPrimary)

                    Text("\(routine.steps.count) steps")
                        .font(.appBodySmall)
                        .foregroundColor(.appTextSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { routine.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(.appAccentPrimary)
        }
        .padding(.vertical, 4)
    }
}
