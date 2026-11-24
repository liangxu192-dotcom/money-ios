import Foundation
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var model: LedgerModel
    @Environment(\.openURL) private var openURL

    @State private var exportURL: URL?
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("自动记账", isOn: $model.autoMode)
                } header: {
                    Text("记账方式")
                } footer: {
                    Text("开启后，从「轻点背面」触发的记账会直接保存；关闭则先打开确认页，核对金额和分类后再存。")
                }

                Section {
                    step(1, "设置 → 辅助功能 → 触控 → 轻点背面")
                    step(2, "轻点三下 → 选择快捷指令「记一笔」")
                    step(3, "说一句「午饭 25」，金额、分类、日期自动填好")
                    Button {
                        if let url = URL(string: "shortcuts://") {
                            openURL(url)
                        }
                    } label: {
                        Label("打开「快捷指令」", systemImage: "arrow.up.forward.app")
                    }
                } header: {
                    Text("轻点背面三下")
                } footer: {
                    Text("轻点背面是 iOS 系统能力，只能触发「快捷指令」，所以要做一次性配置。配置好之后，记账全程在本机完成，不联网。")
                }

                Section {
                    ForEach(model.categories(for: .expense)) { category in
                        HStack(spacing: 10) {
                            Text(category.emoji)
                            Text(category.name)
                            Spacer()
                            Text(category.keywords.prefix(3).joined(separator: "、"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                } header: {
                    Text("支出分类")
                }

                Section {
                    ForEach(model.categories(for: .income)) { category in
                        HStack(spacing: 10) {
                            Text(category.emoji)
                            Text(category.name)
                            Spacer()
                            Text(category.keywords.prefix(3).joined(separator: "、"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                } header: {
                    Text("收入分类")
                }

                Section {
                    LabeledContent("存储位置", value: "仅本机")
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("导出 CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button("清空所有数据", role: .destructive) {
                        showClearConfirm = true
                    }
                } header: {
                    Text("数据")
                } footer: {
                    Text("记录存在 App 沙盒的 ledger.json 里，没有云端副本。卸载 App 即删除。")
                }

                Section {
                    privacyRow("无账号", "不需要登录、没有账号系统", "person.crop.circle.badge.xmark")
                    privacyRow("不联网", "代码里没有网络请求，也没有申请网络权限", "wifi.slash")
                    privacyRow("不读别的 App", "不申请通讯录、相册、定位、麦克风权限", "hand.raised.fill")
                    privacyRow("不出本机", "记账数据只写在本机文件里，可随时导出或删除", "iphone.and.arrow.forward")
                } header: {
                    Text("隐私")
                }

                Section {
                    LabeledContent("版本", value: "1.0")
                    Text("Money · 本地模板工程")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
            .task {
                if exportURL == nil {
                    exportURL = await model.makeCSVFile()
                }
            }
            .onChange(of: model.entries.count) { _, _ in
                Task { exportURL = await model.makeCSVFile() }
            }
            .confirmationDialog("清空后无法恢复", isPresented: $showClearConfirm) {
                Button("清空全部记录", role: .destructive) {
                    Task { await model.deleteAll() }
                }
            }
        }
    }

    private func step(_ index: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.blue))
            Text(text)
                .font(.subheadline)
                .padding(.top, 1)
        }
        .padding(.vertical, 2)
    }

    private func privacyRow(_ title: String, _ detail: String, _ symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 17))
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
