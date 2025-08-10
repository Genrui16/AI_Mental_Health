import Foundation

@MainActor
final class ChatStore {
    static let shared = ChatStore()
    private let fileURL: URL
    
    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("chat_sessions.json")
    }
    
    func loadSessions() -> [ChatSession] {
        guard let data = try? Data(contentsOf: fileURL),
              let sessions = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.date < $1.date }
    }
    
    func saveSession(_ session: ChatSession) {
        var sessions = loadSessions()
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        if let data = try? JSONEncoder().encode(sessions.sorted { $0.date < $1.date }) {
            try? data.write(to: fileURL)
        }
    }
}
