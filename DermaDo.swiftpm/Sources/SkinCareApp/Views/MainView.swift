import SwiftUI

struct MainView: View {
    @EnvironmentObject var dependencies: AppDependencies
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                view(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .tint(.appAccentPrimary)
    }

    @ViewBuilder
    private func view(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .routines:
            RoutinesView()
        case .products:
            ProductsView()
        case .tracker:
            TrackerView()
        case .insights:
            InsightsView()
        case .settings:
            SettingsView()
        }
    }
}
