import Foundation

/// 金额格式化：人民币、两位小数、带千分位。
enum Money {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let plainFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func string(_ value: Decimal) -> String {
        "¥" + (formatter.string(from: value as NSDecimalNumber) ?? "0.00")
    }

    static func plain(_ value: Decimal) -> String {
        plainFormatter.string(from: value as NSDecimalNumber) ?? "0"
    }
}

extension Decimal {
    /// 例如 ¥1,234.50
    var moneyString: String { Money.string(self) }
    /// 例如 1234.5（给输入框用，不带符号和千分位）
    var plainString: String { Money.plain(self) }
    /// 给图表用
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}

extension Date {
    func start(of component: Calendar.Component, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: component, for: self)?.start ?? self
    }
}

extension Notification.Name {
    /// 后台 App Intent 写入账本后广播，前台界面据此刷新。
    static let tallyTapLedgerChanged = Notification.Name("tallytap.ledger.changed")
}
