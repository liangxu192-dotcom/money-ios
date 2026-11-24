import AppIntents
import Foundation

enum LedgerIntentError: LocalizedError {
    case missingAmount

    var errorDescription: String? {
        switch self {
        case .missingAmount:
            return "没识别出金额。试着说「午饭 25」或「昨天打车 18.5」。"
        }
    }
}

/// 静默记账：快捷指令把听写结果传进来，识别后直接落账，不打开 App。
struct QuickAddIntent: AppIntent {
    static let title: LocalizedStringResource = "轻记一笔"
    static let description = IntentDescription("一句话自动识别金额、分类和日期，离线存入本机账本。")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "内容", description: "例如：午饭 25 / 昨天打车 18.5 / 工资 8000")
    var text: String

    init() {}
    init(text: String) { self.text = text }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let parsed = QuickAddParser.parse(text)
        guard let amount = parsed.amount, amount > 0 else {
            throw LedgerIntentError.missingAmount
        }

        let categoryID = parsed.categoryID ?? (parsed.kind == .expense ? "other" : "otherIn")
        let entry = Entry(
            kind: parsed.kind,
            amount: amount,
            categoryID: categoryID,
            note: parsed.note,
            date: parsed.date,
            source: .auto,
            rawText: text
        )
        await LedgerStore.shared.append(entry)

        let categoryName = LedgerCategory.builtin(id: categoryID)?.name ?? "其他"
        let message = "已记 \(parsed.kind.title) \(amount.moneyString) · \(categoryName)"
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

/// 确认记账：打开 App，带着识别结果让你核对后再保存。
struct QuickAddConfirmIntent: AppIntent {
    static let title: LocalizedStringResource = "记一笔（确认）"
    static let description = IntentDescription("打开 Money，核对金额和分类后保存。")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "内容", description: "例如：午饭 25")
    var text: String

    init() {}
    init(text: String) { self.text = text }

    func perform() async throws -> some IntentResult {
        QuickAddBridge.stash(text)
        return .result()
    }
}

/// 让这两个动作出现在「快捷指令」App 和 Siri 里。
struct TallyTapShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: QuickAddIntent(),
                phrases: [
                    "用\(.applicationName)记一笔",
                    "让\(.applicationName)记一笔"
                ],
                shortTitle: "智能记账",
                systemImageName: "bolt.fill"
            ),
            AppShortcut(
                intent: QuickAddConfirmIntent(),
                phrases: [
                    "\(.applicationName)确认记账"
                ],
                shortTitle: "确认后记账",
                systemImageName: "checkmark.circle"
            )
        ]
    }
}
