import Foundation
import SwiftUI

struct EntryEditorSheet: View {
    @EnvironmentObject private var model: LedgerModel
    @Environment(\.dismiss) private var dismiss

    private let entry: Entry

    @State private var amountText: String
    @State private var kind: EntryKind
    @State private var categoryID: String
    @State private var date: Date
    @State private var note: String
    @State private var showDeleteConfirm = false

    init(entry: Entry) {
        self.entry = entry
        _amountText = State(initialValue: entry.amount.plainString)
        _kind = State(initialValue: entry.kind)
        _categoryID = State(initialValue: entry.categoryID)
        _date = State(initialValue: entry.date)
        _note = State(initialValue: entry.note)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("类型", selection: $kind) {
                        Text("支出").tag(EntryKind.expense)
                        Text("收入").tag(EntryKind.income)
                    }
                    .pickerStyle(.segmented)

                    TextField("金额", text: $amountText)
                        .keyboardType(.decimalPad)

                    Picker("分类", selection: $categoryID) {
                        ForEach(model.categories(for: kind)) { category in
                            Text("\(category.emoji) \(category.name)").tag(category.id)
                        }
                    }

                    DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])

                    TextField("备注", text: $note)
                }

                Section {
                    Button("删除这一笔", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(Decimal(string: amountText) == nil)
                }
            }
            .onChange(of: kind) { _, newKind in
                if model.category(for: categoryID).kind != newKind {
                    categoryID = model.categories(for: newKind).first?.id ?? categoryID
                }
            }
            .confirmationDialog("删除后无法恢复", isPresented: $showDeleteConfirm) {
                Button("删除", role: .destructive) {
                    Task {
                        await model.delete(entry)
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: normalized), amount > 0 else { return }
        let updated = Entry(
            id: entry.id,
            kind: kind,
            amount: amount,
            categoryID: categoryID,
            note: note,
            date: date,
            createdAt: entry.createdAt,
            source: entry.source,
            rawText: entry.rawText
        )
        Task {
            await model.update(updated)
            dismiss()
        }
    }
}
