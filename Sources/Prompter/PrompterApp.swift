import SwiftUI

@main
struct PrompterApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(dataStore)
        }
        .defaultSize(width: 1000, height: 700)
        .defaultPosition(.center)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(dataStore)
        }
    }
}
