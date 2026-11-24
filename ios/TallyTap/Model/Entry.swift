import Foundation

/// 一笔账的类型。
enum EntryKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case expense
    case income

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: return "支出"
        case .income: return "收入"
        }
    }

    var sign: String {
        switch self {
        case .expense: return "−"
        case .income: return "+"
        }
    }
}

/// 这一笔是自动记的还是手动记的（明细里会显示小标签）。
enum EntrySource: String, Codable, Sendable {
    case auto
    case manual

    var title: String {
        switch self {
        case .auto: return "自动"
        case .manual: return "手动"
        }
    }
}

/// 账本里的一笔流水。金额用 Decimal，避免浮点误差。
struct Entry: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var kind: EntryKind
    var amount: Decimal
    var categoryID: String
    var note: String
    var date: Date
    var createdAt: Date
    var source: EntrySource
    /// 「轻点背面」时听写进来的原始文本，方便以后追溯识别结果。
    var rawText: String

    init(
        id: UUID = UUID(),
        kind: EntryKind,
        amount: Decimal,
        categoryID: String,
        note: String = "",
        date: Date = Date(),
        createdAt: Date = Date(),
        source: EntrySource = .manual,
        rawText: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.categoryID = categoryID
        self.note = note
        self.date = date
        self.createdAt = createdAt
        self.source = source
        self.rawText = rawText
    }

    var signedAmount: String {
        kind.sign + amount.moneyString
    }

    var displayTitle: String {
        note.isEmpty ? categoryID : note
    }
}
