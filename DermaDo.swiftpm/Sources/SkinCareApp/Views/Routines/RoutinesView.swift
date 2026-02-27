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
    @State private var routineToDelete: Routine?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Void Background + Ambient Orbs
                backgroundLayer

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
                                RoutineCard(
                                    routine: routine,
                                    onToggle: {
                                        viewModel.toggleRoutine(routine)
                                    },
                                    onEdit: {
                                        // No-op — NavigationLink handles it
                                    },
                                    onDelete: {
                                        routineToDelete = routine
                                        showDeleteConfirmation = true
                                    },
                                    editDestination: {
                                        RoutineDetailView(
                                            viewModel: RoutineDetailViewModel(
                                                routineManager: viewModel.routineManager,
                                                mode: .edit(routine)
                                            )
                                        )
                                    }
                                )
                                .editorialReveal(delay: 0.15 + Double(index) * 0.08)
                            }
                        }
                        
                        // We rely on TabView Safe Area, so we remove the manual spacer
                    }
                    .padding(.horizontal, DesignSpacing.large)
                    .padding(.top, DesignSpacing.standard)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.refresh()
        }
        .sheet(isPresented: $showingAddRoutine) {
            RoutineDetailView(viewModel: RoutineDetailViewModel(
                routineManager: viewModel.routineManager,
                mode: .add
            ))
        }
        .alert("Delete Routine", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                routineToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let routine = routineToDelete,
                   let idx = viewModel.routines.firstIndex(where: { $0.id == routine.id }) {
                    viewModel.deleteRoutine(at: idx)
                }
                routineToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this routine?")
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
            VStack(alignment: .leading, spacing: DesignSpacing.micro) {
                Text("SKINCARE RITUALS")
                    .font(DesignTypography.captionUI)
                    .captionTracking()
                    .foregroundColor(DesignColors.liquidSilver)

                Text("Your Routines")
                    .font(DesignTypography.displayEditorial)
                    .foregroundColor(DesignColors.luminousPearl)
            }

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
        VStack(spacing: DesignSpacing.medium) {
            Spacer().frame(height: DesignSpacing.heroic)

            Text("No rituals yet")
                .font(DesignTypography.displayEditorial)
                .foregroundColor(DesignColors.luminousPearl)

            Text("Your daily skincare journey begins with a single ritual.")
                .font(DesignTypography.bodyUI)
                .foregroundColor(DesignColors.liquidSilver)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSpacing.heroic)

            Button(action: { showingAddRoutine = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Ritual")
                }
                .font(DesignTypography.bodyStrongUI)
                .foregroundColor(DesignColors.voidObsidian)
                .padding(.horizontal, DesignSpacing.heroic)
                .padding(.vertical, DesignSpacing.standard)
                .background(Capsule().fill(DesignColors.luminousPearl))
            }
            .padding(.top, DesignSpacing.large)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Routine Card

struct RoutineCard<Destination: View>: View {
    let routine: Routine
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let editDestination: () -> Destination

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
                        .foregroundColor(routine.isEnabled ? iconGlowColor : DesignColors.liquidSilver.opacity(0.3))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: DesignSpacing.small) {
                        Text(routine.name.isEmpty ? "Untitled" : routine.name)
                            .font(DesignTypography.titleUI)
                            .foregroundColor(routine.isEnabled ? DesignColors.luminousPearl : DesignColors.luminousPearl.opacity(0.7))
                            .lineLimit(1)
                        
                        if !routine.isEnabled {
                            Text("PAUSED")
                                .font(DesignTypography.microUI)
                                .captionTracking()
                                .foregroundColor(DesignColors.roseGold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignColors.roseGold.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: DesignSpacing.small) {
                        Text("\(routine.steps.count) steps")
                            .font(DesignTypography.captionUI)
                            .foregroundColor(DesignColors.liquidSilver)

                        Text("·")
                            .foregroundColor(DesignColors.voidAsh)

                        Text(timeLabel)
                            .font(DesignTypography.captionUI)
                            .foregroundColor(DesignColors.liquidSilver)
                        
                        if routine.notifyReminder, let reminderTime = routine.reminderTime {
                            Text("·")
                                .foregroundColor(DesignColors.voidAsh)
                            
                            Text(reminderTime, style: .time)
                                .font(DesignTypography.captionUI)
                                .foregroundColor(DesignColors.roseGold)
                        }
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
                                    .fill(isActive ? (routine.isEnabled ? DesignColors.roseGold.opacity(0.2) : DesignColors.voidAsh.opacity(0.1)) : Color.clear)
                            )
                    }
                }
            }

            // Action Row: Edit + Delete
            HStack(spacing: DesignSpacing.medium) {
                Spacer()
                
                NavigationLink(destination: editDestination()) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignColors.liquidSilver)
                        .frame(width: 36, height: 36)
                        .background(DesignColors.voidAsh.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignColors.roseGold.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(DesignColors.roseGold.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .glassCard()
        .opacity(routine.isEnabled ? 1.0 : 0.5)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(DesignMotion.tactilePress, value: isPressed)
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
