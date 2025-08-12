import Foundation

/// 本地安全过滤器，用于在展示 AI 回复前进行二次审核。
/// 该实现使用关键词与简单规则检测潜在的不当内容；
/// 若要接入在线内容审核，可在此处替换为网络请求。
struct SafetyFilter {
    struct Result {
        let isSafe: Bool
        let reason: String?
    }

    /// 返回是否安全以及原因。仅做基础检测，避免误报阻断正常对话。
    static func review(_ text: String) -> Result {
        let lowered = text.lowercased()
        // 关键词列表（可根据需要扩展/维护）。
        let prohibited: [String] = [
            "自杀", "轻生", "杀死", "炸弹", "仇恨", "种族灭绝",
            "毒品制作", "如何制造", "违法", "血腥", "自残",
            "suicide", "kill myself", "kill you", "harm", "bomb",
            "make meth", "how to make bomb", "hate speech"
        ]
        for word in prohibited {
            if lowered.contains(word.lowercased()) {
                return Result(isSafe: false, reason: "内容可能包含不当或高风险信息（关键词：\(word)）")
            }
        }
        return Result(isSafe: true, reason: nil)
    }
}
