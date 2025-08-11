# MindSync 应用逻辑设计

本文档概述了 MindSync iOS 应用的核心逻辑与数据设计，涵盖日程管理、心理日记与健康数据整合等模块。

## 数据与存储设计
- **日程数据：**使用 Core Data 持久化 `SuggestedEvent`（AI 建议）与 `ActualEvent`（实际活动）实体，启动时可插入示例数据，刷新建议时会先清理旧数据。
- **聊天日记：**`ChatSession` 和 `ChatMessage` 以 JSON 数组形式保存在应用文档目录的 `chat_sessions.json` 文件中，由 `ChatStore` 单例负责读写。
- **健康数据：**通过 `HealthService` 与 Apple HealthKit 交互，按需查询步数、睡眠和心率等指标，不长期存储。
- **情绪日志：**`MoodLog` 结构记录心情与相关说明，目前仅保存在内存中，可扩展为持久化以支持趋势分析。
- **配置与安全：**敏感信息（如 OpenAI API Key）存储在系统 Keychain，少量偏好使用 `UserDefaults` 保存。

## 初次启动与用户引导
- 展示欢迎页并请求 HealthKit、通知等权限。
- 引导用户输入 OpenAI API Key，未设置时 AI 功能受限。
- 首次运行可插入示例活动并创建当天的空 `ChatSession`，避免界面空白。

## 主时间轴 (Timeline)
- 采用两列布局，对比 AI 建议与实际记录，并以纵向时间线连接。
- "刷新" 按钮会调用 `AIService.getDailyScheduleSuggestions` 生成新建议并保存为 `SuggestedEvent`，失败时弹出错误提示。
- 用户可新增、编辑或删除 `ActualEvent` 来记录实际活动。
- 可扩展功能包括完成度统计和本地通知提醒。

## 心理日记 (Diary)
- 支持文本输入、语音转写和情绪评分，消息发送前使用 `SentimentService` 做情感分析。
- 每天使用单独的 `ChatSession` 保存对话历史，可手动开始新会话。
- 发送消息后调用 `AIService.chat` 获得回复，记录保存在本地 JSON 文件中。
- 评分与情绪分析可衍生为 `MoodLog`，为趋势分析和 AI 建议提供依据。

## “我的”页面
- `HealthDataView` 展示从 HealthKit 获取的步数、睡眠和心率等数据。
- `MoodTrendView` 根据 `MoodLog` 绘制心情趋势图，提供时间范围选择和趋势描述。
- 入口还包括日记历史列表和设置页，用于管理 API Key、通知等。

## AI 调用与记忆机制
- AI 调用包括日程建议生成与日记聊天回复，需避免频繁请求以节省资源。
- 应用通过累积的 `MoodLog`、实际活动记录和健康数据形成“记忆”，以便在未来生成更贴合用户状态的建议。
- 所有个人数据默认仅存储在本地，API 通信使用 HTTPS，Keychain 保护敏感信息，确保隐私安全。

