import SwiftUI
import LocalAuthentication

@main
struct ChatServiceApp: App {
    @StateObject var settingsState = SettingsState()
    @StateObject var modelSettings = ModelSettings()
    @StateObject var apiConfig = APIConfig()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ChatViewModel(sessionManager: ChatSessionManager(), apiService: ApiService(apiConfig: apiConfig, modelSettings: modelSettings)))
                .environmentObject(apiConfig)
                .environmentObject(modelSettings)
                .environmentObject(ChatSessionManager())
                .environmentObject(ApiService(apiConfig: apiConfig, modelSettings: modelSettings))
                .environmentObject(settingsState)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings") {
                    settingsState.isSettingsPresent = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
