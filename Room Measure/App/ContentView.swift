import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 1
    @State private var showMeasurement = false
    @State private var navigationResetID = UUID()
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            ProjectsListView()
                .tabItem {
                    Label(LocalizedKey.tabProjects.localized, systemImage: "folder.fill")
                }
                .tag(1)

            Color.clear
                .tabItem {
                    Label(LocalizedKey.tabMeasure.localized, systemImage: "ruler.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label(LocalizedKey.tabSettings.localized, systemImage: "gear")
                }
                .tag(2)
        }
        .id(navigationResetID)
        .accentColor(.blue)
        .environment(\.locale, localizationManager.currentLocale)
        .onChange(of: selectedTab) { oldTab, newTab in
            guard newTab == 0, oldTab != 0 else { return }
            showMeasurement = true
            selectedTab = 1
        }
        .fullScreenCover(isPresented: $showMeasurement) {
            MeasurementContainerView()
        }
        .onChange(of: showMeasurement) { _, isShowing in
            if !isShowing {
                navigationResetID = UUID()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MeasurementProject.self, inMemory: true)
}
