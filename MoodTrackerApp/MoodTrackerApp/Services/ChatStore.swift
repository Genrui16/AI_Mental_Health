import Foundation

@MainActor
final class ChatStore {
    static let shared = ChatStore()
    private let fileURL: URL
    
    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("chat_sessions.json")
    }
    
    func loadSessions() async throws -> [ChatSession] {
        let url = fileURL
        return try await Task.detached(priority: .background) {
            guard FileManager.default.fileExists(atPath: url.path) else { return [] }
            let data = try Data(contentsOf: url)
            let sessions = try JSONDecoder().decode([ChatSession].self, from: data)
            return sessions.sorted { $0.date < $1.date }
        }.value
    }

    func saveSession(_ session: ChatSession) async throws {
        let url = fileURL
        let sessionToSave = session
        try await Task.detached(priority: .background) {
            var sessions: [ChatSession] = []
            if FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                sessions = try JSONDecoder().decode([ChatSession].self, from: data)
            }
            if let index = sessions.firstIndex(where: { $0.id == sessionToSave.id }) {
                sessions[index] = sessionToSave
            } else {
                sessions.append(sessionToSave)
            }
            let data = try JSONEncoder().encode(sessions.sorted { $0.date < $1.date })
            try data.write(to: url)
        }.value
    }
}
