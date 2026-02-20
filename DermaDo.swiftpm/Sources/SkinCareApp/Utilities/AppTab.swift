import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case routines
    case products
    case tracker
    case insights
    case settings

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .routines: return "Routines"
        case .products: return "Products"
        case .tracker: return "Tracker"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .routines: return "list.bullet.clipboard"
        case .products: return "bag"
        case .tracker: return "chart.line.uptrend.xyaxis"
        case .insights: return "sparkles"
        case .settings: return "gearshape"
        }
    }
}
