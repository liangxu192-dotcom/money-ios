import Foundation
import SwiftUI
import UIKit

struct OverviewView: View {
    @EnvironmentObject private var model: LedgerModel
    @State private var period: Period = .month

    enum Period: String, CaseIterable, Identifiable {
        case day, month, year

        var id: String { rawValue }

        var title: String {
            switch self {
            case .day: return "今日"
            case .month: return "本月"
            case .year: return "本年"
            }
        }

        var component: Calendar.Component {
            switch self {
            case .day: return .day
            case .month: return .month
            case .year: return .year
            }
        }
    }

    private var now: Date { Date() }
    private var interval: DateInterval { model.interval(period.component) }
    private var summary: LedgerSummary { model.summary(in: interval) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Picker("统计周期", selection: $period) {
                        ForEach(Period.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    hero
                    tripleCard
                    categoryCard
                    recentCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("char_spongebob")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 26, height: 26)
                            .clipShape(Circle())
                        Text("Money")
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.quickAddPrefill = ""
                        model.showQuickAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("记一笔")
                }
            }
        }
    }

    // MARK: - 主卡片

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(period.title)支出")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(summary.expense.moneyString)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            HStack(spacing: 14) {
                Label(summary.income.moneyString, systemImage: "arrow.down.left.circle.fill")
                Label(summary.balance.moneyString, systemImage: "equal.circle.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            Text(metaText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .card()
    }

    private var metaText: String {
        var text = "共 \(summary.count) 笔"
        switch period {
        case .day:
            text += summary.expense > summary.income ? " · 今天支出偏多" : " · 今天还很有节制"
        case .month:
            let day = Calendar.current.component(.day, from: now)
            let average = summary.expense / Decimal(max(day, 1))
            text += " · 日均支出 \(average.moneyString)"
        case .year:
            let month = Calendar.current.component(.month, from: now)
            let average = summary.expense / Decimal(max(month, 1))
            text += " · 月均支出 \(average.moneyString)"
        }
        return text
    }

    // MARK: - 今日 / 本月 / 本年

    private var tripleCard: some View {
        HStack(spacing: 0) {
            quickCell("今日", interval: model.interval(.day))
            Divider().frame(height: 30)
            quickCell("本月", interval: model.interval(.month))
            Divider().frame(height: 30)
            quickCell("本年", interval: model.interval(.year))
        }
        .card(padding: 14)
    }

    private func quickCell(_ title: String, interval: DateInterval) -> some View {
        let summary = model.summary(in: interval)
        return VStack(spacing: 4) {
            Text(title + "支出")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
            Text(summary.expense.moneyString)
                .font(.system(size: 15, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 分类构成

    private var categoryCard: some View {
        let slices = model.categoryTotals(kind: .expense, in: interval)
        let total = slices.reduce(Decimal(0)) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("分类构成").font(.headline)
                Spacer()
                Text(period.title).font(.caption).foregroundStyle(.secondary)
            }

            if slices.isEmpty {
                Text("这段时间还没有支出")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(Array(slices.prefix(4))) { slice in
                    categoryRow(slice, total: total)
                }
            }
        }
        .card()
    }

    private func categoryRow(_ slice: CategorySlice, total: Decimal) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 8) {
                Text(slice.category.emoji)
                Text(slice.category.name).font(.subheadline)
                Spacer()
                Text(slice.amount.moneyString)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text(percentText(slice.amount, total))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 34, alignment: .trailing)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(uiColor: .tertiarySystemFill))
                    Capsule()
                        .fill(Color(hex: slice.category.colorHex))
                        .frame(width: max(4, proxy.size.width * ratio(slice.amount, total)))
                }
            }
            .frame(height: 6)
        }
    }

    private func ratio(_ amount: Decimal, _ total: Decimal) -> CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat((amount / total).doubleValue)
    }

    private func percentText(_ amount: Decimal, _ total: Decimal) -> String {
        guard total > 0 else { return "0%" }
        return String(format: "%.0f%%", (amount / total).doubleValue * 100)
    }

    // MARK: - 最近记录

    private var recentCard: some View {
        let recent = Array(model.entries.prefix(3))

        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("最近记录").font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)

            if recent.isEmpty {
                Text("还没有记录。点右上角「＋」，或在 iPhone 上轻点背面三下记第一笔。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(recent) { entry in
                    EntryRow(entry: entry, category: model.category(for: entry.categoryID))
                    if entry.id != recent.last?.id {
                        Divider().padding(.leading, 49)
                    }
                }
            }
        }
        .card()
    }
}
