import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var settingsState: SettingsState
    @EnvironmentObject var viewModel: ChatViewModel
    @EnvironmentObject var apiConfig: APIConfig
    @EnvironmentObject var modelSettings: ModelSettings
    @EnvironmentObject var sessionManager: ChatSessionManager
    @EnvironmentObject var apiService: ApiService

    var body: some View {
        HStack {
            ChatSessionsView()
            
            VStack {
                Text("Request:")
                    .font(.title)
                    .padding(.bottom, 4)
                    .padding(.leading, 8)
                
                TextEditor(text: $viewModel.prompt)
                    .frame(height: 200)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                HStack {
                    Button(action: viewModel.clearPrompt) {
                        Image(systemName: "trash")
                            .font(.title)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.sendRequest()
                        }
                    }) {
                        Image(systemName: "paperplane")
                            .font(.title)
                    }
                }
                .padding()
                
                Text("Reply:")
                    .font(.title)
                    .padding(.bottom, 4)
                    .padding(.leading, 8)
                
                TextEditor(text: $viewModel.response)
                    .frame(height: 200)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                HStack {
                    Button(action: viewModel.clearResponse) {
                        Image(systemName: "trash")
                            .font(.title)
                    }
                    
                    Button(action: viewModel.copyResponse) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.title)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $settingsState.isSettingsPresent) {
            SettingsView()
                .environmentObject(apiConfig)
                .environmentObject(modelSettings)
                .environmentObject(sessionManager)
                .environmentObject(apiService)
                .environmentObject(settingsState)
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .background(Color.black.opacity(0.5))
                        .edgesIgnoringSafeArea(.all)
                }
            }
        )
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct ChatSessionsView: View {
    @EnvironmentObject var sessionManager: ChatSessionManager

    var body: some View {
        VStack {
            Text("Chat Sessions:")
                .font(.title2)
                .padding(.bottom, 4)
            
            ScrollView {
                ForEach(sessionManager.sessions, id: \.self) { session in
                    Button(action: {
                        sessionManager.currentSession = session
                    }) {
                        HStack {
                            Text(session)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                            if sessionManager.currentSession == session {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(sessionManager.currentSession == session ? 0.2 : 0))
                        .cornerRadius(8)
                    }
                }
                
                Button(action: sessionManager.createNewSession) {
                    HStack {
                        Text("+ New Session")
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: 200)
            .padding(.horizontal)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var apiConfig: APIConfig
    @EnvironmentObject var modelSettings: ModelSettings
    @EnvironmentObject var settingsState: SettingsState

    var body: some View {
        VStack {
            Form {
                Section(header: Text("API Settings")) {
                    SecureField("API Key", text: $apiConfig.key)
                    TextField("System Prompt", text: $modelSettings.systemMessage)
                }

                Section(header: Text("Model Settings")) {
                    HStack {
                        Text("Temperature:")
                        Slider(value: $modelSettings.temperature, in: 0...1)
                        Text(String(format: "%.2f", modelSettings.temperature))
                    }

                    HStack {
                        Text("Top P:")
                        Slider(value: $modelSettings.topP, in: 0...1)
                        Text(String(format: "%.2f", modelSettings.topP))
                    }

                    HStack {
                        Text("Max Tokens:")
                        Slider(value: Binding(
                            get: { Double(modelSettings.maxTokens) },
                            set: { modelSettings.maxTokens = Int($0) }
                        ), in: 0...128000, step: 1000)
                        Text(String(modelSettings.maxTokens))
                    }
                }

                Section(header: Text("Streaming")) {
                    Toggle("Enable Streaming", isOn: $modelSettings.stream)
                }
            }

            HStack {
                Button("Cancel") {
                    settingsState.isSettingsPresent = false// Reset changes if needed
                }
                .padding()

                Spacer()

                Button("Save") {
                    // Save settings
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 400, height: 450)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SettingsState())
            .environmentObject(ChatViewModel(sessionManager: ChatSessionManager(), apiService: ApiService(apiConfig: APIConfig())))
            .environmentObject(APIConfig())
            .environmentObject(ModelSettings())
            .environmentObject(ChatSessionManager())
            .environmentObject(ApiService(apiConfig: APIConfig()))
    }
}
