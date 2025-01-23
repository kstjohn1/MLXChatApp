//
//  ModelSettings.swift
//  MLXChatApp
//
//  Created by ksj on 1/21/25.
//

import Combine

class ModelSettings: ObservableObject {
    @Published var temperature: Double
    @Published var topP: Double
    @Published var maxTokens: Int
    @Published var stream: Bool
    @Published var systemMessage: String  // Add this property
    
    init(temperature: Double = 0.6, topP: Double = 0.9, maxTokens: Int = 64000, stream: Bool = true, systemMessage: String = "") {
        self.temperature = temperature
        self.topP = topP
        self.maxTokens = maxTokens
        self.stream = stream
        self.systemMessage = systemMessage  // Initialize the new property
    }
}


