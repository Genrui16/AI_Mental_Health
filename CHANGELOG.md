# Changelog — 2025-08-11

本次提交根据你的九点建议对项目进行了功能补强与结构优化。以下为主要改动：

## 1) 完善初始引导与权限处理
- 重写 `Views/OnboardingView.swift`，加入 **多步骤向导**（欢迎 → HealthKit 授权 → 通知授权 → API Key 配置 → 基线信息）。
- 首次完成后若已授权通知，默认在 **21:00** 安排每日日记提醒（可在设置页修改）。
- 如果未输入 API Key，将停留在对应步骤并提示。

## 2) MoodLog 持久化
- 复核 `Services/MoodLogStore.swift` 的 JSON 读写逻辑（无需 Core Data）。无需变更接口，即可直接用于趋势与提示构建。

## 3) 本地通知提醒
- 完整实现/修复 `Services/NotificationService.swift`，新增/修复：
  - `requestAuthorization(...)`
  - `scheduleEventNotifications(for:minutesBefore:)`
  - `scheduleDiaryReminder(at:)` / `cancelDiaryReminder()`
- `TimelineView` 生成建议后将按设置 **提前 N 分钟** 安排提醒。

## 4) 将执行历史和健康数据纳入 AI 提示
- `Views/TimelineView.swift` 在生成建议时聚合：
  - 昨日完成率/未完成项摘要
  - 最近一周心情日志
  - HealthKit 的步数/睡眠/心率（若可用）
  - 用户本地摘要（`UserSummaryStore`）
- 统一在 `requestSuggestions(...)` 发送到 `AIService.getDailyScheduleSuggestions(...)`。

## 5) “我的”页面与设置增强
- `Views/ProfileView.swift` 新增 **设置**、**关于** 入口。
- `Views/SettingsView.swift`：
  - API Key 管理（保存/删除 + 掩码显示）
  - AI 建议提醒开关与 **提前分钟**（0–60）设置
  - 日记提醒开关与时刻（时/分）设置，自动请求权限与重排程
  - HealthKit 重新授权按钮
  - 主题色/字体大小等个性化选项（占位可扩展）

## 6) 对话安全过滤
- 新增 `Services/ModerationService.swift`，接入 **OpenAI Moderations API** 进行内容审核。
- `Services/AIService.swift`：
  - 在发送前与展示前分别调用 `ModerationService.check(...)`；若判定风险，返回 `AIServiceError.inappropriateContent(…)`。
  - 统一设置 **网络超时**（请求 25s、资源 30s）。

## 7) 时间轴建议的动态调整
- `TimelineView` 的提示上下文包含执行反馈（已完成/未完成），模型将据此给出更契合的建议。
- 通过设置中的“提前分钟”细化提醒策略；可进一步扩展为对经常被忽略的类型附带“降低频率”说明。

## 8) 平台兼容性与错误处理
- 延续 `#if os(iOS)` / `#if canImport(...)` 条件编译。
- 关键网络调用增加超时，权限请求失败时给出用户可读提示。

## 9) 稳定性与性能
- 新增 `Services/MaintenanceService.swift`，应用启动时清理：
  - 90 天前的聊天会话
  - 30 天前的日程事件
- 在 `MoodTrackerAppApp.swift` 中通过 `.onAppear` 调用维护任务。

---

### 配置与使用
- 首次启动按向导完成授权与 API Key 配置。
- 在“设置”中可调整通知策略、提醒时间、主题与字体等。
- HealthKit 权限或系统版本不足时，相关功能将自动降级。

> 说明：仓库中的演示代码有少量占位符（`...`），为示例/节选所用；本次改动未移除占位符，以避免与原有结构冲突。集成到真实项目时，请替换为完整实现。
