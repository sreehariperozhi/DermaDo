import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case routines
    case tracker
    case settings

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .routines: return "Routines"
        case .tracker: return "Tracker"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .routines: return "list.bullet.clipboard"
        case .tracker: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape"
        }
    }
}
