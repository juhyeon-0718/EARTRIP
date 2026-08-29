import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "circle.grid.cross") }
            NavigationStack { ExploreView() }
                .tabItem { Label("Explore", systemImage: "location") }
            NavigationStack { MyTripsView() }
                .tabItem { Label("My Trips", systemImage: "figure.walk") }
        }
        .background(EARColor.ivory)
    }
}

