//
//  APIConfig.swift
//  MLXChatApp
//
//  Created by ksj on 1/21/25.
//
import Combine

class APIConfig: ObservableObject {
    @Published var url: String
    @Published var key: String
    
    init(url: String = "http://127.0.0.1:8080/v1/chat/completions", key: String = "") {
        self.url = url
        self.key = key
    }
}

