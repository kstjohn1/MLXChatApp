//
//  ChatServiceApp.swift
//  ChatService
//
//  Created by ksj on 8/9/24.
//

import SwiftUI

@main
struct ChatServiceApp: App {
    @State private var showSettings = false
    @State private var temperature: Double = 0.3
    @State private var topP: Double = 0.9
    @State private var maxTokens: Int = 32000
    @State private var stream: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ContentView(showSettings: $showSettings, temperature: $temperature, topP: $topP, maxTokens: $maxTokens, stream: $stream)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings") {
                    showSettings.toggle()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

