import SwiftUI

struct ContentView: View {
    @Binding var showSettings: Bool
    @Binding var temperature: Double
    @Binding var topP: Double
    @Binding var maxTokens: Int
    @Binding var stream: Bool
    @State private var code = ""
    @State private var response = ""
    @State private var isCopying = false
    
    var body: some View {
        VStack {
            TextEditor(text: $code)
                .frame(height: 200)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            
            Button(action: {
                sendRequest(code: code)
            }) {
                Text("Send Request")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

                TextEditor(text: $response)
                    .frame(height: 200) // Match the height of the request textbox
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                Button(action: {
                    // Copy text to clipboard
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.writeObjects([response as NSString])
                }) {
                    Image(systemName: "doc.on.clipboard")
                       .font(.title)
                }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(temperature: $temperature, topP: $topP, maxTokens: $maxTokens, stream: $stream, onSave: {
                showSettings = false
            }, onCancel: {
                showSettings = false
            })
        }
    }
    
    func sendRequest(code: String) {
        guard let url = constructURL() else {
            print("Invalid URL")
            return
        }
        
        var request = constructURLRequest(url: url)
        request.httpBody = serializeJSON(parameters: constructParameters(code: code))
        
        // Add a separator before starting a new response
        DispatchQueue.main.async {
            self.response += "\n\n---\n\n"
        }
        // Add a separator before starting a new request
        DispatchQueue.main.async {
            self.code += "\n\n---\n\n"
        }
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error)
        }
        task.resume()
    }

    func constructURL() -> URL? {
        return URL(string: "http://127.0.0.1:8080/v1/chat/completions")
    }

    func constructURLRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
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

    func serializeJSON(parameters: [String: Any]) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return nil
        }
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
        
        if let responseString = String(data: data, encoding:.utf8) {
            print("Response String: \(responseString)") // Print the raw response string
            
            // Split the response string into individual JSON objects
            let chunks = responseString.split(separator: "\n")
            for chunk in chunks {
                if chunk.hasPrefix("data: ") {
                    let jsonString = chunk.dropFirst(6) // Remove "data: " prefix
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
                            if let choices = json?["choices"] as? [[String: Any]],
                               let delta = choices.first?["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                DispatchQueue.main.async {
                                    self.response += content
                                }
                            }
                        } catch {
                            print("Error parsing chunk: \(error)")
                        }
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @Binding var temperature: Double
    @Binding var topP: Double
    @Binding var maxTokens: Int
    @Binding var stream: Bool

    var onSave: () -> Void
    var onCancel: () -> Void
    var intProxy: Binding<Double>{
        Binding<Double>(get: {
            //returns the integer as a Double
            return Double(maxTokens)
        }, set: {
            //rounds the double to an Int
            maxTokens = Int($0)
        })
    }
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Model Settings").padding()) {
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
                       // Spacer()
                        Text("Max Tokens:")
                        Slider(value: intProxy, in: 0...128000, step: 1000)
                        Text(String(format: "%.0f", intProxy.wrappedValue))
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

