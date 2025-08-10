# MindSync

## 项目简介

**MindSync** 是一款专注于心理健康和日程管理的 iOS 应用。它利用人工智能提供个性化的日程建议，并结合用户的实际记录和 Apple Health 数据，帮助用户追踪日常活动、情绪变化和健康状况，从而改善心理健康。

## 功能介绍

- **主时间轴 (Timeline)：**  
  展示 AI 建议的日程与用户实际记录，包括运动、用药、饮食、情绪等。  
  用户可对比计划与实际完成情况，形成良好习惯。

- **心理日记：**  
  通过与 AI 对话记录情绪和想法，分析情绪趋势并提供调节建议。

- **我的页面：**  
  集成 Apple Health 数据，展示健康指标、情绪趋势图表及睡眠分析。

- **其他功能：**  
  提供提醒、自定义设置及数据加密保护，保障隐私与安全。

## 技术栈

- **语言与框架**：Swift 5+，SwiftUI
- **平台**：iOS（iPhone，建议 iOS 16+）
- **数据与服务**：HealthKit、Core Data / SQLite、本地通知
- **AI 支持**：自然语言处理与情感分析（Core ML 或 API 调用）

## 部署与运行

1. 克隆项目并使用 Xcode 打开。
2. 在 **Signing & Capabilities** 中启用 **HealthKit**。
3. 连接 iPhone 或使用模拟器（真机可读取真实健康数据）。
4. 点击 **Run** 编译运行，首次启动需授予权限。

## 截图展示

> 以下为占位图，实际界面将在功能完善后替换。

- 主时间轴界面  
  ![timeline](docs/images/timeline_placeholder.png)
- 心理日记界面  
  ![diary](docs/images/diary_placeholder.png)
- 我的页面界面  
  ![health](docs/images/health_placeholder.png)

## 开发计划

- 完善 AI 日记与情绪分析  
- 增加更多记录类型与智能建议  
- 数据云端同步与多设备支持  
- 考虑适配 Apple Watch 与 Mac Catalyst  
- 完成测试后提交 App Store
