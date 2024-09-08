import SwiftUI

struct ContentView: View {
    @Binding var showSettings: Bool
    @Binding var temperature: Double
    @Binding var topP: Double
    @Binding var maxTokens: Int
    @Binding var stream: Bool
    @State private var code = ""
    @State private var response = ""
    @State private var apiUrl = "http://127.0.0.1:8080/v1/chat/completions" // Consider using environment variables or secure storage
    @State private var currentChatSession = "Default Session"
    @State private var chatSessions = ["Default Session"]
    @State private var cachedRequests: [String: String] = [:]
    @State private var cachedResponses: [String: String] = [:]
    @State private var isLoading = false

    var body: some View {
        HStack {
            ChatSessionsView(chatSessions: $chatSessions, currentChatSession: $currentChatSession, cachedRequests: $cachedRequests, cachedResponses: $cachedResponses, loadSession: loadSession, createNewSession: createNewSession)
            
            VStack {
                Text("Request:")
                    .font(.title)
                    .padding(.bottom, 4)
                    .padding(.leading, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextEditor(text: $code)
                    .frame(height: 200)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                HStack {
                    Button(action: clearCode) {
                        Image(systemName: "trash")
                            .font(.title)
                            .help("Delete request")
                    }
                    Button(action: sendRequest) {
                        Image(systemName: "paperplane")
                            .font(.title)
                            .help("Send request")
                    }
                }
                .padding()
                Text("Reply:")
                    .font(.title)
                    .padding(.bottom, 4)
                    .padding(.leading, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextEditor(text: $response)
                    .frame(height: 200)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                HStack {
                    Button(action: clearResponse) {
                        Image(systemName: "trash")
                            .font(.title)
                            .help("Delete replies")
                    }
                    Button(action: copyResponse) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.title)
                            .help("Copy replies")
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(temperature: $temperature, topP: $topP, maxTokens: $maxTokens, stream: $stream, apiUrl: $apiUrl, onSave: {
                showSettings = false
            }, onCancel: {
                showSettings = false
            })
        }
        .overlay(
            Group {
                if isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .background(Color.black.opacity(0.5))
                        .edgesIgnoringSafeArea(.all)
                }
            }
        )
    }

    func sendRequest() {
        isLoading = true
        guard let url = constructURL() else {
            print("Invalid URL")
            isLoading = false
            return
        }

        var request = constructURLRequest(url: url)
        request.httpBody = try? JSONSerialization.data(withJSONObject: constructParameters(code: code), options: [])

        DispatchQueue.main.async {
            self.code += "\n\n---\n\n"
            self.cachedRequests[self.currentChatSession] = self.code
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error)
            isLoading = false
        }
        task.resume()
    }

    func constructURL() -> URL? {
        return URL(string: apiUrl)
    }

    func constructURLRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60.0)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    func constructParameters(code: String) -> [String: Any] {
        return [
            "messages": [
                ["role": "system", "content": ""],
                ["role": "user", "content": code]
            ],
            "temperature": temperature,
            "top_p": topP,
            "max_tokens": maxTokens,
            "stream": stream
        ]
    }

    func handleResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.response += "Error: \(error.localizedDescription)"
            }
            return
        }

        guard let data = data else {
            DispatchQueue.main.async {
                self.response += "No data received"
            }
            return
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("Response String: \(responseString)")

            let chunks = responseString.split(separator: "\n")
            for chunk in chunks {
                if chunk.hasPrefix("data: ") {
                    if chunk.hasPrefix("data: [DONE]") {
                        DispatchQueue.main.async {
                            self.response += "\n\n---\n\n"
                            self.cachedResponses[self.currentChatSession] = self.response
                        }
                        print("Stream is complete, stopping processing")
                        return
                    }
                    let jsonString = chunk.dropFirst(6)
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let delta = choices.first?["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                DispatchQueue.main.async {
                                    self.response += content
                                }
                            }
                        } catch {
                            print("Error parsing chunk: \(error)")
                            DispatchQueue.main.async {
                                self.response += "\n\n---\n\n"
                                self.cachedResponses[self.currentChatSession] = self.response
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self.response += "\n\n---\n\n"
                self.cachedResponses[self.currentChatSession] = self.response
            }
        }
    }

    func clearCode() {
        code = ""
    }

    func clearResponse() {
        response = ""
    }

    func copyResponse() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([response as NSString])
    }

    func createNewSession() {
        let newSessionName = "New Session \(chatSessions.count + 1)"
        chatSessions.append(newSessionName)
        currentChatSession = newSessionName
        cachedRequests[newSessionName] = ""
        cachedResponses[newSessionName] = ""
    }

    func loadSession(session: String) {
        currentChatSession = session
        code = cachedRequests[session] ?? ""
        response = cachedResponses[session] ?? ""
    }
}

struct ChatSessionsView: View {
    @Binding var chatSessions: [String]
    @Binding var currentChatSession: String
    @Binding var cachedRequests: [String: String]
    @Binding var cachedResponses: [String: String]
    var loadSession: (String) -> Void
    var createNewSession: () -> Void

    var body: some View {
        VStack {
            Text("Chat Sessions:")
                .font(.title2)
                .padding(.bottom, 4)
            ScrollView {
                ForEach(chatSessions, id: \.self) { session in
                    Button(action: {
                        currentChatSession = session
                        loadSession(session)
                    }) {
                        HStack {
                            Text(session)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                            if currentChatSession == session {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(currentChatSession == session ? 0.2 : 0))
                        .cornerRadius(8)
                    }
                }
                Button(action: createNewSession) {
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
    @Binding var temperature: Double
    @Binding var topP: Double
    @Binding var maxTokens: Int
    @Binding var stream: Bool
    @Binding var apiUrl: String

    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack {
            Form {
                Section(header: Text("API Settings")
                    .padding()
                    .background(Color.primary)) {
                    TextField("API URL", text: $apiUrl)
                }
                Section(header: Text("Model Settings")
                    .padding()
                    .background(Color.primary)) {
                    HStack {
                        Text("Temperature:")
                        Slider(value: $temperature, in: 0...1)
                        Text(String(format: "%.2f", temperature))
                    }
                    HStack {
                        Text("Top P:")
                        Slider(value: $topP, in: 0...1)
                        Text(String(format: "%.2f", topP))
                    }
                    HStack {
                        Text("Max Tokens:")
                        Slider(value: Binding(get: { Double(maxTokens) }, set: { maxTokens = Int($0) }), in: 0...128000, step: 1000)
                        Text(String(format: "%.0f", Double(maxTokens)))
                    }
                }
                Section(header: Text("Streaming")) {
                    Toggle(isOn: $stream) {
                        Text("Enable Streaming")
                    }
                }
            }
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .padding()

                Spacer()

                Button("Save") {
                    onSave()
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(showSettings: .constant(false), temperature: .constant(0.3), topP: .constant(0.9), maxTokens: .constant(32000), stream: .constant(true))
    }
}
