import Foundation

enum MessageRole: String, Codable {
    case user
    case ai
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    var role: MessageRole
    var text: String
    var sentiment: Double?
    
    init(id: UUID = UUID(), role: MessageRole, text: String, sentiment: Double? = nil) {
        self.id = id
        self.role = role
        self.text = text
        self.sentiment = sentiment
    }
}

struct ChatSession: Identifiable, Codable {
    let id: UUID
    var date: Date
    var messages: [ChatMessage]
    
    init(id: UUID = UUID(), date: Date = Date(), messages: [ChatMessage] = []) {
        self.id = id
        self.date = date
        self.messages = messages
    }
}
