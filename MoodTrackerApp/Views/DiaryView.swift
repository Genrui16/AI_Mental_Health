import SwiftUI

/// 心理日记界面，用户可以通过文本输入与 AI 对话，记录自己的想法和心情。
struct DiaryView: View {
    @State private var diaryText: String = ""
    @State private var chatHistory: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(chatHistory.enumerated()), id: \.offset) { index, message in
                                HStack {
                                    if message.starts(with: "我:") {
                                        Spacer()
                                        Text(message.dropFirst(2))
                                            .padding(8)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    } else {
                                        Text(message.dropFirst(3))
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
                    .onChange(of: chatHistory) { _ in
                        // 滚动到最新消息
                        if let last = chatHistory.indices.last {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }

                Divider()
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
                }
                .padding()
            }
            .navigationTitle("心理日记")
        }
    }

    /// 发送用户输入的文本，并模拟 AI 回复。
    private func sendMessage() {
        let trimmed = diaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatHistory.append("我:" + trimmed)
        diaryText = ""
        // 这里使用 AIService 模拟回复，可替换为实际 API 调用
        let userMessage = trimmed
        AIService.shared.chat(with: userMessage) { reply in
            DispatchQueue.main.async {
                self.chatHistory.append("AI:" + reply)
            }
        }
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
