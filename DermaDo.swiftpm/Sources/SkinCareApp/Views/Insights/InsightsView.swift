import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var dependencies: AppDependencies

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundPrimary.ignoresSafeArea()

                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.appTextTertiary)

                    Text("Insights Coming Soon")
                        .font(.appSectionTitle)
                        .foregroundColor(.appTextPrimary)

                    Text("Personalized skincare insights and recommendations will appear here as you track your routine.")
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xxl)
                }
            }
            .navigationTitle("Insights")
        }
    }
}
