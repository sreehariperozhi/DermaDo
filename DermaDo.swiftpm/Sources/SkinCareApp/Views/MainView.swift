import SwiftUI

struct MainView: View {
    @EnvironmentObject var dependencies: AppDependencies
    @State private var selectedTab: AppTab = .home

    var body: some View {
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                view(for: tab)
                    .tag(tab)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .background(Color.appBackgroundPrimary.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            customTabBar
        }
    }

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.appDivider)
            
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                                .symbolVariant(selectedTab == tab ? .fill : .none)
                            
                            Text(tab.title)
                                .font(.appCaptionText)
                                .fontWeight(selectedTab == tab ? .medium : .regular)
                        }
                        .foregroundColor(selectedTab == tab ? .appAccentPrimary : .appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .contentShape(Rectangle())
                    }
                }
            }
            .background(Color.appCardBackground)
        }
    }

    @ViewBuilder
    private func view(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .routines:
            RoutinesView()
        case .tracker:
            TrackerView()
        case .settings:
            SettingsView()
        }
    }
}
