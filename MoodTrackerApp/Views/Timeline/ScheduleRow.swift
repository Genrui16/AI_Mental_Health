import SwiftUI

/// 单个日程项视图，用于在时间轴中显示建议或实际活动。
struct ScheduleRow: View {
    var item: ScheduleItem
    /// 标记是否为 AI 建议，用于区分颜色或样式。
    var isSuggested: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 使用颜色标识建议（蓝色）与实际记录（绿色）
            Circle()
                .fill(isSuggested ? Color.blue.opacity(0.7) : Color.green.opacity(0.7))
                .frame(width: 8, height: 8)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.time, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.title)
                    .font(.body)
                    .fontWeight(isSuggested ? .medium : .regular)
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - 预览
#if DEBUG
struct ScheduleRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            ScheduleRow(item: ScheduleItem(time: Date(), title: "示例建议"), isSuggested: true)
            ScheduleRow(item: ScheduleItem(time: Date(), title: "示例记录"), isSuggested: false)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
