import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject var dependencies: AppDependencies

    var body: some View {
        RoutinesViewContent(viewModel: RoutinesViewModel(routineManager: dependencies.routineManager))
    }
}

// MARK: - RoutinesViewContent

struct RoutinesViewContent: View {
    @EnvironmentObject var dependencies: AppDependencies
    @StateObject var viewModel: RoutinesViewModel
    @State private var showingAddRoutine = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            // MARK: - Void Background + Ambient Orbs
            backgroundLayer

<<<<<<< HEAD
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
=======
            // MARK: - Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DesignSpacing.large) {

                    // MARK: Header
                    headerSection
                        .editorialReveal(delay: 0.1)

                    if viewModel.routines.isEmpty {
                        emptyState
                            .editorialReveal(delay: 0.2)
                    } else {
                        // MARK: Routine Cards
                        ForEach(Array(viewModel.routines.enumerated()), id: \.element.id) { index, routine in
                            NavigationLink(destination: RoutineDetailView(
                                viewModel: RoutineDetailViewModel(
                                    routineManager: viewModel.routineManager,
                                    mode: .edit(routine)
                                )
                            )) {
                                RoutineCard(routine: routine, onToggle: {
                                    viewModel.toggleRoutine(routine)
                                }, onDelete: {
                                    if let idx = viewModel.routines.firstIndex(where: { $0.id == routine.id }) {
                                        viewModel.deleteRoutine(at: idx)
                                    }
                                })
                            }
                            .buttonStyle(.plain)
                            .editorialReveal(delay: 0.15 + Double(index) * 0.08)
                        }

                        // MARK: Create Button
                        createRoutineButton
                            .editorialReveal(delay: 0.15 + Double(viewModel.routines.count) * 0.08 + 0.1)
                    }

                    // Floating dock clearance
                    Spacer().frame(height: 100)
>>>>>>> mac-ui-major-backup
                }
                .padding(.horizontal, DesignSpacing.large)
                .padding(.top, DesignSpacing.editorial)
            }
        }
        .colorScheme(.dark)
        .onAppear {
            viewModel.refresh()
        }
        .sheet(isPresented: $showingAddRoutine) {
            RoutineDetailView(viewModel: RoutineDetailViewModel(
                routineManager: viewModel.routineManager,
                mode: .add
            ))
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            DesignColors.voidObsidian.ignoresSafeArea()

            // Ambient cerulean orb — top left
            Circle()
                .fill(DesignColors.ceruleanHydration.opacity(0.12))
                .frame(width: 350, height: 350)
                .blur(radius: 120)
                .offset(x: -120, y: -180)

            // Rose gold orb — bottom right
            Circle()
                .fill(DesignColors.roseGold.opacity(0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 100)
                .offset(x: 140, y: 200)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
<<<<<<< HEAD
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
=======
            VStack(alignment: .leading, spacing: DesignSpacing.micro) {
                Text("SKINCARE RITUALS")
                    .font(DesignTypography.captionUI)
                    .captionTracking()
                    .foregroundColor(DesignColors.liquidSilver)

                Text("Your Routines")
                    .font(DesignTypography.displayEditorial)
                    .foregroundColor(DesignColors.luminousPearl)
>>>>>>> mac-ui-major-backup
            }
            .opacity(routine.isEnabled ? 1.0 : 0.5)

            Spacer()

            // Add Button
            Button(action: { showingAddRoutine = true }) {
                ZStack {
                    Circle()
                        .fill(DesignColors.voidAsh.opacity(0.8))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(DesignShadows.innerGlow, lineWidth: 1)
                        )

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignColors.roseGold)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignSpacing.large) {
            Spacer().frame(height: DesignSpacing.heroic)

            ZStack {
                Circle()
                    .fill(DesignColors.voidAsh.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: "list.clipboard")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(DesignColors.liquidSilver.opacity(0.5))
            }

            Text("No Routines Yet")
                .font(DesignTypography.titleUI)
                .foregroundColor(DesignColors.luminousPearl)

            Text("Create your first skincare ritual\nto begin your glow journey.")
                .font(DesignTypography.bodyUI)
                .foregroundColor(DesignColors.liquidSilver)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button(action: { showingAddRoutine = true }) {
                Text("Create Routine")
                    .font(DesignTypography.titleUI)
                    .foregroundColor(DesignColors.voidObsidian)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSpacing.standard)
                    .background(
                        Capsule()
                            .fill(DesignColors.luminousPearl)
                    )
                    .shadow(color: DesignColors.luminousPearl.opacity(0.15), radius: 20, y: 10)
            }
            .padding(.horizontal, DesignSpacing.heroic)
            .padding(.top, DesignSpacing.standard)
        }
    }

    // MARK: - Create Routine Button

    private var createRoutineButton: some View {
        Button(action: { showingAddRoutine = true }) {
            HStack(spacing: DesignSpacing.standard) {
                ZStack {
                    Circle()
                        .fill(DesignColors.roseGold.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignColors.roseGold)
                }

                Text("New Routine")
                    .font(DesignTypography.bodyStrongUI)
                    .foregroundColor(DesignColors.luminousPearl)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignColors.liquidSilver.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .glassCard()
    }
}

// MARK: - Routine Card

struct RoutineCard: View {
    let routine: Routine
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.standard) {
            // Top Row: Icon + Name + Toggle
            HStack(spacing: DesignSpacing.standard) {
                // Time-of-day glow icon
                ZStack {
                    Circle()
                        .fill(iconGlowColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: timeIcon)
                        .font(.system(size: 18))
                        .foregroundColor(routine.isEnabled ? iconGlowColor : DesignColors.voidAsh)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name.isEmpty ? "Untitled" : routine.name)
                        .font(DesignTypography.titleUI)
                        .foregroundColor(routine.isEnabled ? DesignColors.luminousPearl : DesignColors.liquidSilver.opacity(0.5))
                        .lineLimit(1)

                    HStack(spacing: DesignSpacing.small) {
                        Text("\(routine.steps.count) steps")
                            .font(DesignTypography.captionUI)
                            .foregroundColor(DesignColors.liquidSilver)

                        Text("·")
                            .foregroundColor(DesignColors.voidAsh)

                        Text(timeLabel)
                            .font(DesignTypography.captionUI)
                            .foregroundColor(DesignColors.liquidSilver)
                    }
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { routine.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(DesignColors.roseGold)
            }

            // Day pills
            if !routine.repeatDays.isEmpty {
                HStack(spacing: DesignSpacing.small) {
                    ForEach(DayOfWeek.allCases, id: \.self) { day in
                        let isActive = routine.repeatDays.contains(day)
                        Text(dayAbbreviation(day))
                            .font(.system(size: 10, weight: isActive ? .bold : .regular))
                            .foregroundColor(isActive ? DesignColors.luminousPearl : DesignColors.voidAsh)
                            .frame(width: 28, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isActive ? DesignColors.roseGold.opacity(0.2) : Color.clear)
                            )
                    }
                }
            }

            // Chevron hint
            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignColors.liquidSilver.opacity(0.3))
            }
        }
        .glassCard()
        .opacity(routine.isEnabled ? 1.0 : 0.6)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(DesignMotion.tactilePress, value: isPressed)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Routine", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private var timeIcon: String {
        switch routine.timeOfDay {
        case .morning: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .both:    return "clock.fill"
        }
    }

    private var timeLabel: String {
        switch routine.timeOfDay {
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .both:    return "Any Time"
        }
    }

    private var iconGlowColor: Color {
        switch routine.timeOfDay {
        case .morning: return DesignColors.roseGold
        case .evening: return DesignColors.ceruleanHydration
        case .both:    return DesignColors.sageBotanical
        }
    }

    private func dayAbbreviation(_ day: DayOfWeek) -> String {
        switch day {
        case .sunday:    return "S"
        case .monday:    return "M"
        case .tuesday:   return "T"
        case .wednesday: return "W"
        case .thursday:  return "T"
        case .friday:    return "F"
        case .saturday:  return "S"
        }
    }
}
