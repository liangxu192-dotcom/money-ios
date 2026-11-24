import Foundation

/// 一个记账分类。关键词用于离线识别（「午饭」→ 餐饮）。
struct LedgerCategory: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var kind: EntryKind
    var name: String
    var emoji: String
    var colorHex: String
    var keywords: [String]
    var sortIndex: Int
    var isBuiltin: Bool

    init(
        id: String,
        kind: EntryKind,
        name: String,
        emoji: String,
        colorHex: String,
        keywords: [String] = [],
        sortIndex: Int = 0,
        isBuiltin: Bool = true
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.keywords = keywords
        self.sortIndex = sortIndex
        self.isBuiltin = isBuiltin
    }
}

extension LedgerCategory {
    static func builtin(id: String) -> LedgerCategory? {
        builtins.first { $0.id == id }
    }

    static let builtins: [LedgerCategory] = [
        // 支出
        LedgerCategory(id: "food", kind: .expense, name: "餐饮", emoji: "🍜", colorHex: "#FF9500",
                       keywords: ["早饭", "早餐", "午饭", "午餐", "晚饭", "晚餐", "夜宵", "外卖", "咖啡", "奶茶",
                                  "火锅", "烧烤", "面包", "水果", "零食", "食堂", "豆浆", "油条", "面条", "饭"],
                       sortIndex: 0),
        LedgerCategory(id: "transport", kind: .expense, name: "交通", emoji: "🚇", colorHex: "#0A84FF",
                       keywords: ["地铁", "公交", "打车", "滴滴", "出租车", "高铁", "火车", "机票", "加油",
                                  "停车", "单车", "通勤"],
                       sortIndex: 1),
        LedgerCategory(id: "shopping", kind: .expense, name: "购物", emoji: "🛍️", colorHex: "#FF2D55",
                       keywords: ["超市", "淘宝", "京东", "网购", "衣服", "鞋", "化妆", "日用品", "纸巾",
                                  "洗发水", "袜子", "水果店"],
                       sortIndex: 2),
        LedgerCategory(id: "home", kind: .expense, name: "居住", emoji: "🏠", colorHex: "#5856D6",
                       keywords: ["房租", "水费", "电费", "燃气", "物业", "宽带", "煤气"],
                       sortIndex: 3),
        LedgerCategory(id: "fun", kind: .expense, name: "娱乐", emoji: "🎮", colorHex: "#AF52DE",
                       keywords: ["电影", "游戏", "演出", "门票", "健身", "会员", "订阅", "KTV", "剧本杀"],
                       sortIndex: 4),
        LedgerCategory(id: "health", kind: .expense, name: "医疗", emoji: "💊", colorHex: "#34C759",
                       keywords: ["医院", "药店", "吃药", "挂号", "体检", "牙医", "诊所"],
                       sortIndex: 5),
        LedgerCategory(id: "study", kind: .expense, name: "学习", emoji: "📚", colorHex: "#00C7BE",
                       keywords: ["书", "课程", "学费", "培训", "考试", "文具", "网课"],
                       sortIndex: 6),
        LedgerCategory(id: "social", kind: .expense, name: "人情", emoji: "🎁", colorHex: "#FF6B22",
                       keywords: ["礼物", "份子", "请客", "生日"],
                       sortIndex: 7),
        LedgerCategory(id: "other", kind: .expense, name: "其他", emoji: "📦", colorHex: "#8E8E93",
                       keywords: [],
                       sortIndex: 8),

        // 收入
        LedgerCategory(id: "salary", kind: .income, name: "工资", emoji: "💼", colorHex: "#34C759",
                       keywords: ["工资", "薪水", "发薪"],
                       sortIndex: 0),
        LedgerCategory(id: "bonus", kind: .income, name: "奖金", emoji: "🏆", colorHex: "#FF9500",
                       keywords: ["奖金", "提成", "年终"],
                       sortIndex: 1),
        LedgerCategory(id: "reimburse", kind: .income, name: "报销", emoji: "🧾", colorHex: "#0A84FF",
                       keywords: ["报销", "退款", "返现"],
                       sortIndex: 2),
        LedgerCategory(id: "invest", kind: .income, name: "理财", emoji: "📈", colorHex: "#5856D6",
                       keywords: ["利息", "分红", "基金", "股票", "理财", "收益"],
                       sortIndex: 3),
        LedgerCategory(id: "redpacket", kind: .income, name: "红包", emoji: "🧧", colorHex: "#FF3B30",
                       keywords: ["红包", "礼金", "收到"],
                       sortIndex: 4),
        LedgerCategory(id: "otherIn", kind: .income, name: "其他", emoji: "💰", colorHex: "#8E8E93",
                       keywords: ["卖", "二手", "兼职", "稿费"],
                       sortIndex: 5)
    ]
}
