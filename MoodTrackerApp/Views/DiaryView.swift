import SwiftUI
import NaturalLanguage

/// 心理日记界面，用户可以通过文本、语音或评分与 AI 对话，记录自己的想法和心情。
struct DiaryView: View {
    @State private var diaryText: String = ""
    @State private var chatHistory: [ChatMessage] = []
    @State private var currentSession = ChatSession()
    @StateObject private var speechService = SpeechService()
    @State private var showRatingSheet = false
    @State private var rating: Double = 5

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                messageList
                Divider()
                inputBar
            }
            .navigationTitle("心理日记")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新会话", action: newSession)
                }
            }
            .onAppear(perform: loadSession)
            .onChange(of: speechService.transcribedText) { text in
                diaryText = text
            }
            .sheet(isPresented: $showRatingSheet) {
                ratingSheet
            }
        }
    }

    // MARK: - 子视图

    /// 聊天消息列表
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(chatHistory.enumerated()), id: \.element.id) { index, message in
                        messageView(for: message)
                            .id(index)
                    }
                }
                .padding()
            }
            .onChange(of: chatHistory) { _ in
                if let last = chatHistory.indices.last {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }

    /// 单条消息视图
    @ViewBuilder
    private func messageView(for message: ChatMessage) -> some View {
        HStack {
            if message.role == .user {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    if let sentiment = message.sentiment {
                        Text("情绪: \(SentimentService.shared.label(for: sentiment)) (\(String(format: \"%.2f\", sentiment)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                Spacer()
            }
        }
    }

    /// 输入栏
    private var inputBar: some View {
        HStack {
            TextField("写下你的想法...", text: $diaryText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3)
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
            }
            .disabled(diaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.leading, 8)
            Button(action: toggleRecording) {
                Image(systemName: speechService.isRecording ? "stop.circle" : "mic.fill")
                    .font(.system(size: 20))
            }
            .padding(.leading, 4)
            Button(action: { showRatingSheet = true }) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 20))
            }
            .padding(.leading, 4)
        }
        .padding()
    }

    /// 评分表单
    private var ratingSheet: some View {
        VStack(spacing: 20) {
            Text("情绪评分")
                .font(.title3)
            Slider(value: $rating, in: 1...10, step: 1)
            Text("评分: \(Int(rating))")
            Button("提交", action: sendRating)
                .padding(.top, 10)
        }
        .padding()
    }

    /// 发送用户输入的文本，并进行情感分析和持久化。
    private func sendMessage() {
        let trimmed = diaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let sentiment = SentimentService.shared.analyze(trimmed)
        let message = ChatMessage(role: .user, text: trimmed, sentiment: sentiment)
        currentSession.messages.append(message)
        chatHistory = currentSession.messages
        diaryText = ""
        ChatStore.shared.saveSession(currentSession)
        AIService.shared.chat(with: trimmed) { reply in
            DispatchQueue.main.async {
                let replyMessage = ChatMessage(role: .ai, text: reply)
                self.currentSession.messages.append(replyMessage)
                self.chatHistory = self.currentSession.messages
                ChatStore.shared.saveSession(self.currentSession)
            }
        }
    }

    /// 发送情绪评分。
    private func sendRating() {
        let text = "情绪评分: \(Int(rating))"
        let message = ChatMessage(role: .user, text: text, sentiment: nil)
        currentSession.messages.append(message)
        chatHistory = currentSession.messages
        ChatStore.shared.saveSession(currentSession)
        showRatingSheet = false
        rating = 5
    }

    /// 开始或停止语音识别。
    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            speechService.startRecording()
        }
    }

    /// 加载最近的会话。
    private func loadSession() {
        let sessions = ChatStore.shared.loadSessions()
        if let last = sessions.last {
            currentSession = last
        } else {
            currentSession = ChatSession()
            ChatStore.shared.saveSession(currentSession)
        }
        chatHistory = currentSession.messages
    }

    /// 开始新的会话。
    private func newSession() {
        ChatStore.shared.saveSession(currentSession)
        currentSession = ChatSession()
        chatHistory = []
        ChatStore.shared.saveSession(currentSession)
    }
}

// MARK: - 预览
#if DEBUG
struct DiaryView_Previews: PreviewProvider {
    static var previews: some View {
        DiaryView()
    }
}
#endif
