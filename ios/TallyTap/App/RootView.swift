import Combine
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: LedgerModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            OverviewView()
                .tabItem {
                    Label { Text("概览") } icon: { Image("char_spongebob").renderingMode(.original) }
                }
            DetailView()
                .tabItem {
                    Label { Text("明细") } icon: { Image("char_patrick").renderingMode(.original) }
                }
            StatsView()
                .tabItem {
                    Label { Text("统计") } icon: { Image("char_sandy").renderingMode(.original) }
                }
            SettingsView()
                .tabItem {
                    Label { Text("我的") } icon: { Image("char_krabs").renderingMode(.original) }
                }
        }
        .tint(.blue)
        .sheet(isPresented: $model.showQuickAdd) {
            QuickAddSheet(prefill: model.quickAddPrefill)
        }
        .task {
            await model.reload()
            model.consumePendingQuickAdd()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await model.reload()
                model.consumePendingQuickAdd()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tallyTapLedgerChanged)) { _ in
            Task { await model.reload() }
        }
        .overlay(alignment: .top) {
            if let toast = model.toast {
                ToastView(text: toast)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: toast) {
                        do {
                            try await Task.sleep(for: .seconds(2.2))
                            withAnimation { model.toast = nil }
                        } catch {
                            // 被新的 toast 替换时取消，不做处理
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.toast)
    }
}
