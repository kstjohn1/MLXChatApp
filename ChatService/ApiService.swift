import Combine
import Foundation
import SwiftUI

@MainActor
class ApiService: ObservableObject {
    private let apiConfig: APIConfig
    @Published var modelSettings: ModelSettings

    init(apiConfig: APIConfig, modelSettings: ModelSettings) {
        self.apiConfig = apiConfig
        self.modelSettings = modelSettings
    }

    @Published var lastResponse: String? = nil

    func sendRequest(prompt: String, systemMessage: String) async throws -> String {
        guard !prompt.isEmpty else {
            throw NSError(domain: "Invalid Request", code: 1, userInfo: [NSLocalizedDescriptionKey: "Please enter a request."])
        }

        guard let url = URL(string: apiConfig.url) else {
            throw NSError(domain: "Invalid URL", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint."])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiConfig.key)", forHTTPHeaderField: "Authorization")

        let parameters = [
            "messages": [
                ["role": "system", "content": systemMessage],
                ["role": "user", "content": prompt]
            ],
            "temperature": modelSettings.temperature,
            "top_p": modelSettings.topP,
            "max_tokens": modelSettings.maxTokens,
            "stream": modelSettings.stream
        ] as [String : Any]

        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Network Error", code: 3, userInfo: [NSLocalizedDescriptionKey: "No data received."])
        }

        let parsedResponse = try parseResponse(responseString)
        self.lastResponse = parsedResponse
        return parsedResponse
    }

    private func parseResponse(_ response: String) throws -> String {
        var result = ""
        let chunks = response.split(separator: "\n")

        for chunk in chunks {
            if chunk.hasPrefix("data: ") {
                let jsonString = String(chunk.dropFirst(6))
                if let json = try? JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let delta = choices.first?["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    result += content
                }
            }
        }
        return result
    }
}
