import SwiftUI

@main
struct PrompterApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(dataStore)
                .frame(minWidth: 600, minHeight: 500)
                .background(Theme.backgroundGradient)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 700, height: 550)

        Settings {
            SettingsView()
                .environmentObject(dataStore)
                .preferredColorScheme(.dark)
        }

        MenuBarExtra("Prompter", systemImage: "sparkles") {
            VStack(spacing: 12) {
                Text("Prompter")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                Button("Open Window") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title.contains("Prompter") || $0.contentView != nil }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)

                Divider()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
            .padding()
            .frame(width: 180)
            .background(Theme.surface)
        }
        .menuBarExtraStyle(.window)
    }
}
