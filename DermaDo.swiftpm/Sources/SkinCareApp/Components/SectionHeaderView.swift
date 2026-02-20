import SwiftUI

struct SectionHeaderView: View {
    let title: String
    var actionTitle: String? = nil
    var showSeparator: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .appFont(.sectionTitle)
                    .foregroundColor(.appTextPrimary)

                Spacer()

                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .appFont(.labelMedium)
                            .foregroundColor(.appAccentPrimary)
                    }
                }
            }
            .frame(minHeight: 40)

            if showSeparator {
                Divider()
                    .background(Color.appDivider)
            }
        }
    }
}
