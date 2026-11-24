import Foundation
import SwiftUI
import UIKit

struct DetailView: View {
    @EnvironmentObject private var model: LedgerModel
    @State private var month: Date = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    @State private var filter: EntryKind?
    @State private var editing: Entry?

    private var monthInterval: DateInterval {
        Calendar.current.dateInterval(of: .month, for: month) ?? DateInterval(start: month, duration: 0)
    }

    private var summary: LedgerSummary {
        model.summary(in: monthInterval)
    }

    private var groups: [DayGroup] {
        let allGroups = model.groups(in: monthInterval)
        guard let filter else { return allGroups }
        return allGroups.compactMap { group in
            let filtered = group.entries.filter { $0.kind == filter }
            return filtered.isEmpty ? nil : DayGroup(date: group.date, entries: filtered)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    monthBar
                    summaryStrip
                    filterChips

                    if groups.isEmpty {
                        Text("这个月还没有记录")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(groups) { group in
                            daySection(group)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("明细")
            .toolbar {
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
            .sheet(item: $editing) { entry in
                EntryEditorSheet(entry: entry)
                    .environmentObject(model)
            }
        }
    }

    // MARK: - 月份切换

    private var monthBar: some View {
        HStack(spacing: 18) {
            Button {
                shift(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color(uiColor: .tertiarySystemFill)))
            }
            .buttonStyle(.plain)

            Text(month, format: .dateTime.year().month())
                .font(.headline)
                .frame(minWidth: 110)

            Button {
                shift(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color(uiColor: .tertiarySystemFill)))
            }
            .buttonStyle(.plain)
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0.35 : 1)
        }
        .frame(maxWidth: .infinity)
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(month, equalTo: Date(), toGranularity: .month)
    }

    private func shift(_ delta: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: delta, to: month) else { return }
        if delta > 0 && newMonth > Date() { return }
        month = newMonth
    }

    // MARK: - 汇总条

    private var summaryStrip: some View {
        HStack(spacing: 0) {
            summaryCell("支出", value: summary.expense.moneyString, color: .primary)
            Divider().frame(height: 28)
            summaryCell("收入", value: summary.income.moneyString, color: .green)
            Divider().frame(height: 28)
            summaryCell("笔数", value: "\(summary.count)", color: .primary)
        }
        .card(padding: 12)
    }

    private func summaryCell(_ title: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.system(size: 11.5)).foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 筛选

    private var filterChips: some View {
        HStack(spacing: 8) {
            chip("全部", kind: nil)
            chip("支出", kind: .expense)
            chip("收入", kind: .income)
            Spacer()
        }
    }

    private func chip(_ title: String, kind: EntryKind?) -> some View {
        Button {
            filter = kind
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(filter == kind ? Color.primary : Color(uiColor: .tertiarySystemFill))
                )
                .foregroundStyle(filter == kind ? Color(uiColor: .systemBackground) : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 按天分组

    private func daySection(_ group: DayGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(group.date, format: .dateTime.day().month())
                    .font(.system(size: 13, weight: .bold))
                Text(group.date, format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(dayTotals(group))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach(group.entries) { entry in
                    EntryRow(entry: entry, category: model.category(for: entry.categoryID))
                        .onTapGesture { editing = entry }
                    if entry.id != group.entries.last?.id {
                        Divider().padding(.leading, 49)
                    }
                }
            }
            .card(padding: 14)
        }
    }

    private func dayTotals(_ group: DayGroup) -> String {
        var parts: [String] = []
        if group.expense > 0 { parts.append("支 \(group.expense.moneyString)") }
        if group.income > 0 { parts.append("收 \(group.income.moneyString)") }
        return parts.joined(separator: " · ")
    }
}
