import SwiftUI

@main
struct PrompterApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(dataStore)
        }

        MenuBarExtra("Prompter", systemImage: "terminal") {
            MainView()
                .environmentObject(dataStore)
                .frame(width: 500, height: 400)
        }
        .menuBarExtraStyle(.window)
    }
}
