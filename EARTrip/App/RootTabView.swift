import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("발견", systemImage: "binoculars") }
            NavigationStack { ExploreView() }
                .tabItem { Label("둘러보기", systemImage: "map") }
            NavigationStack { MyTripsView() }
                .tabItem { Label("내 여행", systemImage: "person") }
        }
        .background(EARColor.ivory)
        .tint(EARColor.forest)
        .toolbarBackground(EARColor.ivory, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
