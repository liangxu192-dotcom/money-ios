import Foundation
import SwiftUI
import UIKit

struct QuickAddSheet: View {
    @EnvironmentObject private var model: LedgerModel
    @Environment(\.dismiss) private var dismiss

    private let fromBackTap: Bool

    @State private var text: String
    @State private var amountText: String
    @State private var kind: EntryKind
    @State private var categoryID: String
    @State private var date: Date
    @State private var note: String
    @FocusState private var inputFocused: Bool

    init(prefill: String = "", fromBackTap: Bool = false) {
        self.fromBackTap = fromBackTap

        if prefill.isEmpty {
            _text = State(initialValue: "")
            _amountText = State(initialValue: "")
            _kind = State(initialValue: .expense)
            _categoryID = State(initialValue: "food")
            _date = State(initialValue: Date())
            _note = State(initialValue: "")
        } else {
            let parsed = QuickAddParser.parse(prefill)
            _text = State(initialValue: prefill)
            _amountText = State(initialValue: parsed.amount?.plainString ?? "")
            _kind = State(initialValue: parsed.kind)
            _categoryID = State(initialValue: parsed.categoryID ?? (parsed.kind == .expense ? "other" : "otherIn"))
            _date = State(initialValue: parsed.date)
            _note = State(initialValue: parsed.note)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if fromBackTap {
                        Label("轻点背面 ×3 触发", systemImage: "hand.tap.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                    }

                    inputField
                    previewCard
                    autoNote

                    Button(action: save) {
                        Text("保存")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(Decimal(string: amountText) == nil)
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .onChange(of: text) { _, newValue in
            applyParse(newValue)
        }
        .onChange(of: kind) { _, newKind in
            if model.category(for: categoryID).kind != newKind {
                categoryID = model.categories(for: newKind).first?.id ?? categoryID
            }
        }
        .onAppear {
            inputFocused = text.isEmpty
        }
    }

    // MARK: - 输入

    private var inputField: some View {
        HStack(spacing: 8) {
            TextField("说一句，或输入：午饭 25", text: $text)
                .focused($inputFocused)
                .submitLabel(.done)
                .onSubmit { inputFocused = false }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - 识别结果

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                CategoryBadge(category: model.category(for: categoryID), size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.category(for: categoryID).name).font(.headline)
                    Text(dateText).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                Text(kind.sign + (Decimal(string: amountText) ?? 0).moneyString)
                    .font(.system(size: 20, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(kind == .income ? Color.green : Color.primary)
            }

            TextField("金额", text: $amountText)
                .keyboardType(.decimalPad)
                .font(.system(size: 26, weight: .heavy))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                )

            Picker("类型", selection: $kind) {
                Text("支出").tag(EntryKind.expense)
                Text("收入").tag(EntryKind.income)
            }
            .pickerStyle(.segmented)

            categoryPicker

            HStack {
                Text("日期")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("日期", selection: $date, displayedComponents: [.date])
                    .labelsHidden()
            }

            TextField("备注（可不填）", text: $note)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                )
        }
        .card()
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(model.categories(for: kind)) { category in
                    Button {
                        categoryID = category.id
                    } label: {
                        Text("\(category.emoji) \(category.name)")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(
                                    categoryID == category.id
                                        ? Color.blue.opacity(0.15)
                                        : Color(uiColor: .tertiarySystemFill)
                                )
                            )
                            .foregroundStyle(categoryID == category.id ? Color.blue : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dateText: String {
        if Calendar.current.isDateInToday(date) {
            return "今天 · " + date.formatted(.dateTime.month().day())
        }
        return date.formatted(.dateTime.year().month().day())
    }

    private var autoNote: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: model.autoMode ? "bolt.fill" : "hand.tap.fill")
                .foregroundStyle(model.autoMode ? Color.green : Color.secondary)
            Text(model.autoMode
                 ? "自动记账已开启：从「轻点背面」进来的这一笔会直接入账，不再二次确认。"
                 : "自动记账已关闭：每次都停在这一页，核对金额和分类后再保存。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 动作

    private func applyParse(_ value: String) {
        guard !value.isEmpty else { return }
        let parsed = QuickAddParser.parse(value)
        kind = parsed.kind
        categoryID = parsed.categoryID ?? (parsed.kind == .expense ? "other" : "otherIn")
        date = parsed.date
        note = parsed.note
        if let amount = parsed.amount {
            amountText = amount.plainString
        }
    }

    private func save() {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: normalized), amount > 0 else { return }
        let entry = Entry(
            kind: kind,
            amount: amount,
            categoryID: categoryID,
            note: note,
            date: date,
            source: fromBackTap ? .auto : .manual,
            rawText: text
        )
        Task {
            await model.add(entry)
            dismiss()
        }
    }
}
