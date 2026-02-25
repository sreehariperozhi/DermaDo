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
                    // Minimal Empty State
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 32))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.appTextTertiary.opacity(0.6))

                        Text("Your collection is empty")
                            .font(.appBody)
                            .foregroundColor(.appTextTertiary)
                            .multilineTextAlignment(.center)
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
                    withAnimation(DesignMotion.editorialSpring) {
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
                HStack(spacing: AppSpacing.sm) {
                    Text(routine.name)
                        .font(.appHeading3)
                        .foregroundColor(routine.isEnabled ? .appTextPrimary : .appTextTertiary)
                    
                    if !routine.isEnabled {
                        Text("PAUSED")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appTextTertiary.opacity(0.3))
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: routine.timeOfDay == .morning ? "sun.max" : routine.timeOfDay == .evening ? "moon.stars" : "clock")
                        .font(.system(size: 12))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.appAccentPrimary)

                    Text("\(routine.steps.count) steps")
                        .font(.appBodySmall)
                        .foregroundColor(.appTextSecondary)
                    
                    if routine.notifyReminder, let time = routine.reminderTime {
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(.appTextTertiary)
                        
                        Image(systemName: "bell.badge")
                            .font(.system(size: 10))
                            .foregroundColor(.appAccentPrimary)
                        
                        Text(time, style: .time)
                            .font(.appBodySmall)
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .opacity(routine.isEnabled ? 1.0 : 0.5)

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
