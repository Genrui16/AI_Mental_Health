#if os(iOS)
import SwiftUI

/// 单个日程项视图，用于在时间轴中显示建议或实际活动。
struct ScheduleRow: View {
    var item: ScheduleItem
    /// 标记是否为 AI 建议，用于区分颜色或样式。
    var isSuggested: Bool
    /// 当为建议项时的完成状态。
    var isCompleted: Bool = false
    /// 切换完成状态的动作，仅对建议项有效。
    var onToggleCompleted: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isSuggested {
                Button(action: { onToggleCompleted?() }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCompleted ? .green : .blue)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            } else {
                // 使用颜色标识实际记录（绿色）
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
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
#endif
