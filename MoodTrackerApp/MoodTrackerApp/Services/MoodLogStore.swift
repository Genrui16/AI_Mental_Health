import Foundation

@MainActor
final class MoodLogStore {
    static let shared = MoodLogStore()
    private let fileURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("mood_logs.json")
    }

    func loadLogs() -> [MoodLog] {
        guard let data = try? Data(contentsOf: fileURL),
              let logs = try? JSONDecoder().decode([MoodLog].self, from: data) else {
            return []
        }
        return logs.sorted { $0.time < $1.time }
    }

    func addLog(_ log: MoodLog) {
        var logs = loadLogs()
        logs.append(log)
        if let data = try? JSONEncoder().encode(logs.sorted { $0.time < $1.time }) {
            try? data.write(to: fileURL)
        }
    }

    func recentLogs(days: Int) -> [MoodLog] {
        let logs = loadLogs()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return logs.filter { $0.time >= startDate }
    }
}

