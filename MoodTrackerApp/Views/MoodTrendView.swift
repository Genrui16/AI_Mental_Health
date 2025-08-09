import SwiftUI

/// 心情趋势视图，用于展示用户的情绪变化和节律评分趋势图。
struct MoodTrendView: View {
    @EnvironmentObject var appData: AppData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("心情趋势")
                .font(.title2)
            if appData.moodLogs.isEmpty {
                Text("暂无心情记录")
                    .font(.body)
            } else {
                ForEach(appData.moodLogs) { log in
                    Text("\(log.time, formatter: dateFormatter) - \(log.mood)")
                        .font(.body)
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("心情趋势")
    }
}

private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .short
    f.timeStyle = .short
    return f
}()

// MARK: - 预览
#if DEBUG
struct MoodTrendView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MoodTrendView().environmentObject(AppData())
        }
    }
}
#endif
