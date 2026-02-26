import SwiftUI

struct DayPickerView: View {
    @Binding var selectedDays: Set<DayOfWeek>

    var body: some View {
        HStack(spacing: DesignSpacing.small) {
            ForEach(DayOfWeek.allCases, id: \.self) { day in
                DayButton(day: day, isSelected: selectedDays.contains(day)) {
                    toggle(day)
                }
            }
        }
    }

    private func toggle(_ day: DayOfWeek) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedDays.contains(day) {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
            }
        }
    }
}

private struct DayButton: View {
    let day: DayOfWeek
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(abbreviation(for: day))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? DesignColors.voidObsidian : DesignColors.luminousPearl)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? DesignColors.roseGold : DesignColors.voidAsh.opacity(0.3))
                        .overlay(
                            Circle()
                                .stroke(DesignShadows.innerGlow, lineWidth: 1)
                                .opacity(isSelected ? 0.3 : 0.1)
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(DesignMotion.editorialSpring, value: isSelected)
    }

    private func abbreviation(for day: DayOfWeek) -> String {
        switch day {
        case .monday:    return "M"
        case .tuesday:   return "T"
        case .wednesday: return "W"
        case .thursday:  return "T"
        case .friday:    return "F"
        case .saturday:  return "S"
        case .sunday:    return "S"
        }
    }
}
