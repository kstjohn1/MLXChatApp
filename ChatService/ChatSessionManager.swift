//
//  ChatSessionManager.swift
//  MLXChatApp
//
//  Created by ksj on 1/21/25.
//
import SwiftUI

class ChatSessionManager: ObservableObject {
    @Published var currentSession: String = "Default Session"
    @Published var sessions: [String] = ["Default Session"]
    @Published var cachedRequests: [String: String] = [:]
    @Published var cachedResponses: [String: String] = [:]
    
    func createNewSession() {
        let newSessionName = "Session \(sessions.count + 1)"
        sessions.append(newSessionName)
        currentSession = newSessionName
        cachedRequests[newSessionName] = ""
        cachedResponses[newSessionName] = ""
    }
    
    func loadSession(_ session: String) {
        currentSession = session
    }
}
