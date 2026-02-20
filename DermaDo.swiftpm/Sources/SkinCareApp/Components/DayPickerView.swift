import SwiftUI

struct DayPickerView: View {
    @Binding var selectedDays: Set<DayOfWeek>

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
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
                .font(.appLabelMedium)
                .foregroundColor(isSelected ? .white : .appTextSecondary)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(isSelected ? Color.appAccentPrimary : Color.appCardBackground)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
