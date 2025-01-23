import SwiftUI
import LocalAuthentication

@main
struct ChatServiceApp: App {
    @StateObject var settingsState = SettingsState()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ChatViewModel(sessionManager: ChatSessionManager(), apiService: ApiService(apiConfig: APIConfig())))
                .environmentObject(APIConfig())
                .environmentObject(ModelSettings())
                .environmentObject(ChatSessionManager())
                .environmentObject(ApiService(apiConfig: APIConfig()))
                .environmentObject(settingsState)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings") {
                    // Show settings view
                    settingsState.isSettingsPresent = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
