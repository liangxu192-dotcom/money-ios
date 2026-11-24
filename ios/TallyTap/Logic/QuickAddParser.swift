import Foundation

/// 识别结果。金额可能识别不出来（此时 UI 要求手填）。
struct ParsedEntry: Sendable {
    var amount: Decimal?
    var kind: EntryKind
    var categoryID: String?
    var date: Date
    var note: String
    var matchedKeyword: String?
    var confidence: Double
}

/// 离线记账解析器：金额 + 相对日期 + 类型 + 关键词分类。
/// 不联网、不调用模型，随便说一句就能落账。
enum QuickAddParser {

    static func parse(
        _ rawText: String,
        categories: [LedgerCategory] = LedgerCategory.builtins,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ParsedEntry {
        let text = normalize(rawText)
        var working = text
        var date = now
        var dateToken: String?

        // 1. 相对日期：昨天 / 前天 / 大前天 / 今天
        let relativeDays: [(String, Int)] = [("大前天", -3), ("前天", -2), ("昨天", -1), ("今天", 0)]
        for (word, offset) in relativeDays where text.contains(word) {
            if let shifted = calendar.date(byAdding: .day, value: offset, to: now) {
                date = shifted
            }
            dateToken = word
            working = working.replacingOccurrences(of: word, with: " ")
            break
        }

        // 2. 完整日期：11月20日
        if dateToken == nil,
           let groups = match(#"(\d{1,2})\s*月\s*(\d{1,2})\s*[日号]?"#, in: text),
           groups.count >= 3,
           let month = Int(groups[1]),
           let day = Int(groups[2]),
           (1...12).contains(month),
           (1...31).contains(day),
           let dateValue = calendar.date(from: DateComponents(
               year: calendar.component(.year, from: now),
               month: month,
               day: day
           )) {
            date = dateValue
            dateToken = groups[0]
            working = working.replacingOccurrences(of: groups[0], with: " ")
        }

        // 3. 只写了日：20日 / 20号
        if dateToken == nil,
           let groups = match(#"(?:^|[^\d])(\d{1,2})\s*[日号]"#, in: text),
           groups.count >= 2,
           let day = Int(groups[1].trimmingCharacters(in: .whitespaces)),
           (1...31).contains(day),
           let dateValue = calendar.date(from: DateComponents(
               year: calendar.component(.year, from: now),
               month: calendar.component(.month, from: now),
               day: day
           )) {
            date = dateValue
            let token = groups[0].trimmingCharacters(in: .whitespaces)
            dateToken = token
            working = working.replacingOccurrences(of: token, with: " ")
        }

        // 去掉 12:30 这类时间，避免被当成金额
        working = working.replacingOccurrences(of: #"\d{1,2}\s*[:：]\s*\d{2}"#, with: " ", options: .regularExpression)

        // 4. 金额
        let amountResult = extractAmount(from: working)
        let amount = amountResult?.value
        let amountToken = amountResult?.token

        // 5. 支出 / 收入
        let kind = detectKind(text)

        // 6. 分类
        let (categoryID, keyword) = detectCategory(text, kind: kind, categories: categories)

        // 7. 备注：把日期、金额、货币符号去掉，剩下的就是备注
        var note = working
        if let amountToken {
            note = note.replacingOccurrences(of: amountToken, with: " ")
        }
        note = note.replacingOccurrences(of: "[¥￥元块]", with: " ", options: .regularExpression)
        note = note.replacingOccurrences(of: "[，,。.！!？?、]", with: " ", options: .regularExpression)
        note = note.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if note.isEmpty {
            note = categories.first(where: { $0.id == categoryID })?.name ?? "一笔"
        }

        var confidence = 0.0
        if amount != nil { confidence += 0.5 }
        if keyword != nil { confidence += 0.3 }
        if dateToken != nil { confidence += 0.1 }
        if amount != nil && !note.isEmpty { confidence += 0.1 }

        return ParsedEntry(
            amount: amount,
            kind: kind,
            categoryID: categoryID,
            date: date,
            note: note,
            matchedKeyword: keyword,
            confidence: min(confidence, 1)
        )
    }

    // MARK: - 金额

    private static func extractAmount(from text: String) -> (value: Decimal, token: String)? {
        var arabic: [(value: Decimal, token: String, marked: Bool)] = []

        if let regex = try? NSRegularExpression(pattern: #"\d+(?:\.\d{1,2})?"#) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches {
                guard let range = Range(match.range, in: text) else { continue }
                let token = String(text[range])
                guard let value = Decimal(string: token) else { continue }
                let after = text[range.upperBound...].prefix(2)
                let before = text[..<range.lowerBound].suffix(1)
                let marked = after.hasPrefix("元") || after.hasPrefix("块") || before == "¥" || before == "￥"
                arabic.append((value, token, marked))
            }
        }

        if let hit = arabic.last(where: { $0.marked }) ?? arabic.last {
            return (hit.value, hit.token)
        }

        // 中文数字：三十、二十五、两百
        if let groups = match(#"[零〇一二两三四五六七八九十百千万点]{1,6}"#, in: text),
           let token = groups.first,
           let value = ChineseNumber.value(token) {
            return (value, token)
        }

        return nil
    }

    // MARK: - 支出 / 收入

    private static func detectKind(_ text: String) -> EntryKind {
        let incomeHints = ["工资", "薪", "奖金", "提成", "报销", "退款", "返现", "利息", "分红",
                           "收益", "红包", "礼金", "收到", "进账", "收入", "兼职", "稿费"]
        let expenseHints = ["花", "付", "买", "支出", "消费"]
        let incomeScore = incomeHints.filter { text.contains($0) }.count
        let expenseScore = expenseHints.filter { text.contains($0) }.count
        return incomeScore > expenseScore ? .income : .expense
    }

    // MARK: - 分类

    private static func detectCategory(
        _ text: String,
        kind: EntryKind,
        categories: [LedgerCategory]
    ) -> (id: String?, keyword: String?) {
        var best: (id: String, keyword: String, length: Int)?

        for category in categories where category.kind == kind {
            for keyword in category.keywords where !keyword.isEmpty && text.contains(keyword) {
                if best == nil || keyword.count > best!.length {
                    best = (category.id, keyword, keyword.count)
                }
            }
        }

        if let best {
            return (best.id, best.keyword)
        }
        return (kind == .expense ? "other" : "otherIn", nil)
    }

    // MARK: - 工具

    private static func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? trimmed
    }

    /// 返回完整匹配 + 各捕获组；groups[0] 是完整匹配。
    private static func match(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let result = regex.firstMatch(in: text, range: range) else { return nil }

        var groups: [String] = []
        for index in 0..<result.numberOfRanges {
            if let groupRange = Range(result.range(at: index), in: text) {
                groups.append(String(text[groupRange]))
            } else {
                groups.append("")
            }
        }
        return groups
    }
}

/// 中文数字 → Decimal（支持 二十五、两百、一千零五、三点五）。
enum ChineseNumber {
    private static let digits: [Character: Int] = [
        "零": 0, "〇": 0, "一": 1, "二": 2, "两": 2, "三": 3, "四": 4,
        "五": 5, "六": 6, "七": 7, "八": 8, "九": 9
    ]
    private static let units: [Character: Int] = ["十": 10, "百": 100, "千": 1000]

    static func value(_ text: String) -> Decimal? {
        let parts = text.split(separator: "点", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        guard let integerPart = parts.first, let integer = integerValue(integerPart) else { return nil }
        guard parts.count == 2 else { return integer }

        var fraction = Decimal(0)
        var scale = Decimal(1)
        for character in parts[1] {
            guard let digit = digits[character] else { return nil }
            scale /= 10
            fraction += Decimal(digit) * scale
        }
        return integer + fraction
    }

    private static func integerValue(_ text: String) -> Decimal? {
        guard !text.isEmpty else { return nil }
        var total = 0
        var section = 0
        var number = 0
        var sawNumber = false

        for character in text {
            if let digit = digits[character] {
                number = digit
                sawNumber = true
            } else if let unit = units[character] {
                section += max(number, 1) * unit
                number = 0
                sawNumber = true
            } else if character == "万" {
                section += number
                total += section * 10_000
                section = 0
                number = 0
                sawNumber = true
            } else {
                return nil
            }
        }

        guard sawNumber else { return nil }
        return Decimal(total + section + number)
    }
}
