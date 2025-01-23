import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var response: String = ""
    @Published var systemMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    @EnvironmentObject var apiConfig: APIConfig
    @EnvironmentObject var modelSettings: ModelSettings
    let sessionManager: ChatSessionManager
    let apiService: ApiService
    
    init(sessionManager: ChatSessionManager, apiService: ApiService) {
        self.apiService = apiService   // Direct Assignment
        self.sessionManager = sessionManager
    }
    
    @MainActor
    func sendRequest() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.prompt += "\n\n---\n\n"
            let newResponse = try await apiService.sendRequest(prompt: prompt, systemMessage: systemMessage)
            if !self.response.isEmpty {
                self.response += "\n\n---\n\n"
            }
            self.response += newResponse
            sessionManager.cachedResponses[sessionManager.currentSession] = newResponse
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func clearPrompt() {
        prompt = ""
    }
    
    func clearResponse() {
        response = ""
    }
    
    func copyResponse() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([response as NSString])
    }
}
