import Foundation
import SwiftUI

struct LedgerSummary {
    var expense: Decimal = 0
    var income: Decimal = 0
    var count: Int = 0
    var balance: Decimal { income - expense }
}

struct CategorySlice: Identifiable {
    var category: LedgerCategory
    var amount: Decimal
    var id: String { category.id }
}

struct DayGroup: Identifiable {
    var date: Date
    var entries: [Entry]
    var id: Date { date }

    var expense: Decimal { entries.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount } }
    var income: Decimal { entries.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount } }
}

@MainActor
final class LedgerModel: ObservableObject {
    private static let autoModeKey = "tallytap.autoMode"

    @Published private(set) var entries: [Entry] = []
    @Published var autoMode: Bool {
        didSet { UserDefaults.standard.set(autoMode, forKey: Self.autoModeKey) }
    }
    @Published var showQuickAdd = false
    @Published var quickAddPrefill = ""
    @Published var toast: String?

    let categories: [LedgerCategory] = LedgerCategory.builtins

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.autoModeKey) == nil {
            autoMode = true
        } else {
            autoMode = defaults.bool(forKey: Self.autoModeKey)
        }
    }

    // MARK: - 读写

    func reload() async {
        entries = await LedgerStore.shared.load()
        entries.sort { $0.date > $1.date }
    }

    func add(_ entry: Entry) async {
        await LedgerStore.shared.append(entry)
        await reload()
        toast = "已记 \(entry.kind.title) \(entry.amount.moneyString) · \(category(for: entry.categoryID).name)"
    }

    func update(_ entry: Entry) async {
        await LedgerStore.shared.update(entry)
        await reload()
        toast = "已保存修改"
    }

    func delete(_ entry: Entry) async {
        await LedgerStore.shared.delete(id: entry.id)
        await reload()
        toast = "已删除一笔记录"
    }

    func deleteAll() async {
        await LedgerStore.shared.replaceAll([])
        await reload()
        toast = "已清空全部记录"
    }

    /// 「确认后记账」快捷指令会把文本放进 UserDefaults，前台读取后弹出确认页。
    func consumePendingQuickAdd() {
        guard let text = QuickAddBridge.take() else { return }
        quickAddPrefill = text
        showQuickAdd = true
    }

    func makeCSVFile() async -> URL? {
        let csv = await LedgerStore.shared.exportCSV()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let fileName = "Money-\(formatter.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try ("\u{FEFF}" + csv).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - 查询

    func category(for id: String) -> LedgerCategory {
        categories.first { $0.id == id } ?? categories[0]
    }

    func categories(for kind: EntryKind) -> [LedgerCategory] {
        categories.filter { $0.kind == kind }
    }

    func interval(_ component: Calendar.Component, date: Date = Date()) -> DateInterval {
        Calendar.current.dateInterval(of: component, for: date)
            ?? DateInterval(start: date, duration: 0)
    }

    func summary(in interval: DateInterval) -> LedgerSummary {
        var summary = LedgerSummary()
        for entry in entries where interval.contains(entry.date) {
            if entry.kind == .expense {
                summary.expense += entry.amount
            } else {
                summary.income += entry.amount
            }
            summary.count += 1
        }
        return summary
    }

    func categoryTotals(kind: EntryKind, in interval: DateInterval) -> [CategorySlice] {
        var sums: [String: Decimal] = [:]
        for entry in entries where entry.kind == kind && interval.contains(entry.date) {
            sums[entry.categoryID, default: 0] += entry.amount
        }
        return sums
            .map { CategorySlice(category: category(for: $0.key), amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    func groups(in interval: DateInterval) -> [DayGroup] {
        let calendar = Calendar.current
        var buckets: [Date: [Entry]] = [:]
        for entry in entries where interval.contains(entry.date) {
            let day = calendar.startOfDay(for: entry.date)
            buckets[day, default: []].append(entry)
        }
        return buckets
            .map { DayGroup(date: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }
}
