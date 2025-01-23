//
//  Message.swift
//  MLXChatApp
//
//  Created by ksj on 1/21/25.
//

struct Message {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}
