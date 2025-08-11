#if os(iOS)
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
    @State private var showingAPIKeyPrompt = false
    @State private var apiKeyInput: String = ""
    @State private var showSpeechError = false

    /// 简单敏感词列表，用于过滤 AI 回复中的不当内容。
    private let bannedWords = ["自杀", "伤害自己", "自残", "杀人"]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                chatList
                Divider()
                inputSection
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
            .onChange(of: speechService.errorMessage) { _ in
                showSpeechError = speechService.errorMessage != nil
            }
            .sheet(isPresented: $showRatingSheet) {
                ratingSheetContent
            }
        }
        .alert("语音识别", isPresented: $showSpeechError) {
            Button("确定", role: .cancel) { speechService.errorMessage = nil }
        } message: {
            Text(speechService.errorMessage ?? "")
        }
        .alert("设置 API Key", isPresented: $showingAPIKeyPrompt) {
            TextField("API Key", text: $apiKeyInput)
            Button("保存") {
                KeychainService.shared.saveAPIKey(apiKeyInput)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("使用此功能需要设置 OpenAI API Key")
        }
    }

    /// 聊天记录列表
    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(dateFormatter.string(from: currentSession.date))
                        .font(.headline)
                        .padding(.bottom, 4)
                    ForEach(Array(chatHistory.enumerated()), id: \.element.id) { index, message in
                        chatRow(message)
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

    /// 单条聊天消息行
    private func chatRow(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    if let sentiment = message.sentiment {
                        let label = SentimentService.shared.label(for: sentiment)
                        let formatted = String(format: "%.2f", sentiment)
                        Text("情绪: \(label) (\(formatted))")
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

    /// 输入区域
    private var inputSection: some View {
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

    /// 评分表单内容
    private var ratingSheetContent: some View {
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
        guard KeychainService.shared.getAPIKey() != nil else {
            showingAPIKeyPrompt = true
            return
        }
        let sentiment = SentimentService.shared.analyze(trimmed)
        let message = ChatMessage(role: .user, text: trimmed, sentiment: sentiment)
        currentSession.messages.append(message)
        chatHistory = currentSession.messages
        diaryText = ""
        ChatStore.shared.saveSession(currentSession)

        // 显示 AI 正在思考的占位消息
        let placeholder = ChatMessage(role: .ai, text: "AI 正在思考…")
        currentSession.messages.append(placeholder)
        chatHistory = currentSession.messages

        // 调用 AI 服务，并传递最近的对话历史（排除占位消息）
        AIService.shared.chat(with: Array(currentSession.messages.dropLast())) { result in
            DispatchQueue.main.async {
                if let index = self.currentSession.messages.firstIndex(where: { $0.id == placeholder.id }) {
                    self.currentSession.messages.remove(at: index)
                }
                let text: String
                switch result {
                case .success(let reply):
                    text = self.sanitizeResponse(reply)
                case .failure(let error):
                    text = error.localizedDescription
                }
                let replyMessage = ChatMessage(role: .ai, text: text)
                self.currentSession.messages.append(replyMessage)
                self.chatHistory = self.currentSession.messages
                ChatStore.shared.saveSession(self.currentSession)
            }
        }
    }

    /// 发送情绪评分。
    private func sendRating() {
        let score = Int(rating)
        let text = "情绪评分: \(score)"
        let message = ChatMessage(role: .user, text: text, sentiment: nil)
        currentSession.messages.append(message)
        chatHistory = currentSession.messages
        ChatStore.shared.saveSession(currentSession)

        let mood: String
        switch score {
        case ..<3: mood = "非常不好"
        case 3..<5: mood = "不好"
        case 5..<7: mood = "一般"
        case 7..<9: mood = "好"
        default: mood = "很好"
        }
        let log = MoodLog(time: Date(), mood: mood, description: text)
        MoodLogStore.shared.addLog(log)

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

    /// 过滤 AI 回复中的敏感内容。
    private func sanitizeResponse(_ text: String) -> String {
        for word in bannedWords {
            if text.contains(word) {
                return "抱歉，我无法回答该请求。"
            }
        }
        return text
    }

    /// 加载或创建当天的会话。
    private func loadSession() {
        let today = Date()
        let sessions = ChatStore.shared.loadSessions()
        if let existing = sessions.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            currentSession = existing
        } else {
            currentSession = ChatSession(date: today)
            ChatStore.shared.saveSession(currentSession)
        }
        chatHistory = currentSession.messages
    }

    /// 开始新的会话。
    private func newSession() {
        ChatStore.shared.saveSession(currentSession)
        currentSession = ChatSession(date: Date())
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
#endif
