import Charts
import Foundation
import SwiftUI
import UIKit

struct MonthStat: Identifiable {
    let id: Int
    let label: String
    let expense: Double
}

struct StatsView: View {
    @EnvironmentObject private var model: LedgerModel

    private let calendar = Calendar.current

    private var year: Int { calendar.component(.year, from: Date()) }
    private var yearInterval: DateInterval { model.interval(.year) }
    private var totals: LedgerSummary { model.summary(in: yearInterval) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    chartCard
                    rankCard
                    compareCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("统计")
        }
    }

    // MARK: - 月度支出

    private var months: [MonthStat] {
        (1...12).map { month in
            let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
            let interval = calendar.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 0)
            let summary = model.summary(in: interval)
            return MonthStat(id: month, label: "\(month)", expense: summary.expense.doubleValue)
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("月度支出").font(.headline)
                Spacer()
                Text("\(String(year)) 年").font(.caption).foregroundStyle(.secondary)
            }

            Chart(months) { item in
                BarMark(
                    x: .value("月份", item.label),
                    y: .value("支出", item.expense)
                )
                .foregroundStyle(Color.red.gradient)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 170)
        }
        .card()
    }

    // MARK: - 年度分类排行

    private var rankCard: some View {
        let slices = model.categoryTotals(kind: .expense, in: yearInterval)
        let total = slices.reduce(Decimal(0)) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("年度分类排行").font(.headline)
                Spacer()
                Text("支出").font(.caption).foregroundStyle(.secondary)
            }

            if slices.isEmpty {
                Text("今年还没有支出")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(Array(slices.prefix(6))) { slice in
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
            }
        }
        .card()
    }

    private func ratio(_ amount: Decimal, _ total: Decimal) -> CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat((amount / total).doubleValue)
    }

    private func percentText(_ amount: Decimal, _ total: Decimal) -> String {
        guard total > 0 else { return "0%" }
        return String(format: "%.0f%%", (amount / total).doubleValue * 100)
    }

    // MARK: - 全年概况

    private var compareCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("全年概况").font(.headline)

            HStack(spacing: 0) {
                compareCell("全年支出", totals.expense.moneyString, color: .primary)
                Divider().frame(height: 30)
                compareCell("全年收入", totals.income.moneyString, color: .green)
                Divider().frame(height: 30)
                compareCell(
                    "全年结余",
                    totals.balance.moneyString,
                    color: totals.balance >= 0 ? .green : .red
                )
            }
        }
        .card()
    }

    private func compareCell(_ title: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.system(size: 11)).foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}
