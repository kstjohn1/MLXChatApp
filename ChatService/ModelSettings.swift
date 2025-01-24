//
//  ModelSettings.swift
//  MLXChatApp
//
//  Created by ksj on 1/21/25.
//

import Combine
import Foundation

class ModelSettings: ObservableObject {
    @Published var temperature: Double
    @Published var topP: Double
    @Published var maxTokens: Int
    @Published var stream: Bool
    @Published var systemMessage: String
    
    init(
        temperature: Double = UserDefaults.standard.double(forKey: "temperature") != 0 ? UserDefaults.standard.double(forKey: "temperature") : 0.6,
        topP: Double = UserDefaults.standard.double(forKey: "topP") != 0 ? UserDefaults.standard.double(forKey: "topP") : 0.9,
        maxTokens: Int = UserDefaults.standard.integer(forKey: "maxTokens") != 0 ? UserDefaults.standard.integer(forKey: "maxTokens") : 32000,
        stream: Bool = !UserDefaults.standard.bool(forKey: "stream") ? false : true,
        systemMessage: String = UserDefaults.standard.string(forKey: "systemMessage") ?? ""
    ) {
        self.temperature = temperature
        self.topP = topP
        self.maxTokens = maxTokens
        self.stream = stream
        self.systemMessage = systemMessage
    }
}
