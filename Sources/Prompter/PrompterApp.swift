import SwiftUI

@main
struct PrompterApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(dataStore)
                .background(Theme.backgroundGradient)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 650)
        .defaultPosition(.center)

        Settings {
            SettingsView()
                .environmentObject(dataStore)
                .preferredColorScheme(.dark)
        }
    }
}
