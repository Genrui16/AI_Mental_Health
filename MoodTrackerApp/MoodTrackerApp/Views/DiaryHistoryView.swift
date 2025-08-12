#if os(iOS)
import SwiftUI

/// 日记历史列表，可在“我的”页面查看所有记录。
struct DiaryHistoryView: View {
    @State private var sessions: [ChatSession] = []

    fileprivate static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        List(sessions) { session in
            NavigationLink(destination: DiarySessionDetailView(session: session)) {
                Text(Self.dateFormatter.string(from: session.date))
            }
        }
        .navigationTitle("日记记录")
        .onAppear {
            sessions = ChatStore.shared.loadSessions().sorted { $0.date < $1.date }
        }
    }
}

/// 查看单个会话的详细内容。
struct DiarySessionDetailView: View {
    let session: ChatSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(session.messages) { message in
                    HStack {
                        if message.role == .user {
                            Spacer()
                            Text(message.text)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            Text(message.text)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(DiaryHistoryView.dateFormatter.string(from: session.date))
    }
}
#endif
