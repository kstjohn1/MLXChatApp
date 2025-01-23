//
//  APIConfig.swift
//  MLXChatApp
//
//  Created by ksj on 1/21/25.
//
import Combine
import Foundation

class APIConfig: ObservableObject {
    @Published var url: String
    @Published var key: String
    
    init(url: String = UserDefaults.standard.string(forKey: "apiURL") ?? "http://127.0.0.1:8080/v1/chat/completions", key: String = UserDefaults.standard.string(forKey: "apiKey") ?? "") {
        self.url = url
        self.key = key
    }
}

