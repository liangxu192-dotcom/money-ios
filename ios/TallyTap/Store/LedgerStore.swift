import Foundation

/// 账本的唯一数据源：一个 JSON 文件，存在 App 沙盒里。
/// 没有数据库、没有网络、没有账号——卸载 App 就彻底删除。
actor LedgerStore {
    static let shared = LedgerStore()

    private let fileURL: URL
    private var cache: [Entry]?

    init() {
        let fileManager = FileManager.default
        let baseURL = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory

        let directory = baseURL.appendingPathComponent("TallyTap", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("ledger.json")
    }

    func load() -> [Entry] {
        if let cache { return cache }
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? Self.decoder.decode([Entry].self, from: data) else {
            cache = []
            return []
        }
        cache = entries
        return entries
    }

    @discardableResult
    func append(_ entry: Entry) -> [Entry] {
        var entries = load()
        entries.append(entry)
        persist(entries)
        NotificationCenter.default.post(name: .tallyTapLedgerChanged, object: nil)
        return entries
    }

    func update(_ entry: Entry) {
        var entries = load()
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        persist(entries)
        NotificationCenter.default.post(name: .tallyTapLedgerChanged, object: nil)
    }

    func delete(id: UUID) {
        persist(load().filter { $0.id != id })
        NotificationCenter.default.post(name: .tallyTapLedgerChanged, object: nil)
    }

    func replaceAll(_ entries: [Entry]) {
        persist(entries)
        NotificationCenter.default.post(name: .tallyTapLedgerChanged, object: nil)
    }

    /// 导出 CSV（带 BOM，Excel 打开不乱码）。
    func exportCSV() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        var lines = ["日期,类型,分类,备注,金额,来源"]
        for entry in load().sorted(by: { $0.date < $1.date }) {
            let note = entry.note.replacingOccurrences(of: ",", with: "，")
            let categoryName = LedgerCategory.builtin(id: entry.categoryID)?.name ?? entry.categoryID
            let amount = NSDecimalNumber(decimal: entry.amount).stringValue
            lines.append("\(dateFormatter.string(from: entry.date)),\(entry.kind.title),\(categoryName),\(note),\(amount),\(entry.source.title)")
        }
        return lines.joined(separator: "\n")
    }

    private func persist(_ entries: [Entry]) {
        cache = entries
        guard let data = try? Self.encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
