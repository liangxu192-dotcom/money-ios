import Foundation

/// 「确认后记账」快捷指令与 App 之间的桥：把待确认文本暂存到 UserDefaults。
enum QuickAddBridge {
    private static let key = "tallytap.pendingQuickAdd"

    static func stash(_ text: String) {
        UserDefaults.standard.set(text, forKey: key)
    }

    static func take() -> String? {
        let value = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
        return value
    }
}
