# ios/ · 可编译模板（Money）

SwiftUI + App Intents + 本地 JSON 账本，最低 iOS 17。没有第三方依赖。
桌面上显示的名字是 **Money**，App 图标与底栏角色图来自提供的插画。

## 构建

```bash
brew install xcodegen
cd ios
xcodegen generate
open TallyTap.xcodeproj
```

Xcode 里设置 Team、改 Bundle Identifier，选 iOS 17 真机 Run。

> 只能跑在 Mac 上；Windows 没有 iOS 工具链。

## 轻点背面三下（原生版专属）

1. iPhone：`设置 → 辅助功能 → 触控 → 轻点背面 → 轻点三下`。
2. 先在「快捷指令」里新建一条 **记一笔**：
   - 动作 1：`听写文本`
   - 动作 2：搜索「Money」→ **轻记一笔** → 把听写结果填进 `内容`
3. 回到轻点背面，选择这条快捷指令。

想保存前核对，就把动作 2 换成 **记一笔（确认）**，它会打开 App 停在确认页。
网页版（`pwa/`）没有这个入口——iOS 不允许网页被背面轻点唤起。

## 品牌与角色

- 图标：`TallyTap/Assets.xcassets/AppIcon.appiconset/icon-1024.png`（海绵宝宝 + 派大星）。
- 底栏四个 tab 用角色头像：`char_spongebob` / `char_patrick` / `char_sandy` / `char_krabs`，都已设为 `original` 渲染模式，不会被系统染成单色。
- 概览页标题栏左侧是 Money 字标 + 海绵宝宝头像。
- 角色插画 © Nickelodeon，仅限个人自用，不要上架 App Store。

## 文件地图

```
TallyTap/
├─ Assets.xcassets/          App 图标（icon-1024）+ 六个角色头像（char_*）
├─ App/
│  ├─ TallyTapApp.swift      @main，注入 LedgerModel
│  └─ RootView.swift         四个 Tab、全局 toast、快捷指令桥接、场景回到前台时刷新
├─ Model/
│  ├─ Entry.swift            一笔账（Decimal 金额、类型、分类、时间、来源、原始文本）
│  ├─ LedgerCategory.swift   15 个内置分类 + 关键词（识别靠它）
│  └─ Formatters.swift       金额格式化、Date 扩展、通知名
├─ Logic/
│  └─ QuickAddParser.swift   离线识别：日期 → 金额 → 类型 → 分类 → 备注；中文数字
├─ Store/
│  ├─ LedgerStore.swift      actor，ledger.json 读写、CSV 导出；写入后发通知
│  └─ LedgerModel.swift      @MainActor ObservableObject，缓存 + 汇总 + 分组
├─ Intents/
│  ├─ TallyTapIntents.swift  两个 App Intent + AppShortcutsProvider
│  └─ QuickAddBridge.swift   「确认后记账」用 UserDefaults 把文本带进 App
├─ Views/
│  ├─ OverviewView.swift     今日/本月/本年，总览、分类构成、最近记录
│  ├─ DetailView.swift       按月、按天分组，筛选，点一行进入编辑
│  ├─ StatsView.swift        12 个月柱状图（Charts）、年度分类排行、全年概况
│  ├─ SettingsView.swift     自动记账开关、轻点背面步骤、分类、导出、隐私
│  ├─ QuickAddSheet.swift    一句话识别 + 可改金额/分类/日期/备注
│  ├─ EntryEditorSheet.swift 编辑/删除已有记录
│  └─ Components.swift       卡片样式、分类徽章、流水行、toast
└─ PrivacyInfo.xcprivacy     声明不收集数据、不追踪
```

## 数据流

```
轻点背面 → 快捷指令「记一笔」→ 听写文本
   → QuickAddIntent.perform()
        → QuickAddParser.parse()        纯函数，离线
        → LedgerStore.append()          actor 写 JSON
        → NotificationCenter 广播
   → RootView 收到通知 → LedgerModel.reload() → 界面刷新
```

手动记账走同一套：`QuickAddSheet` → `LedgerModel.add()` → `LedgerStore`。

## 关键实现说明

- **为什么用 JSON 而不是 SwiftData**：一份「本地小账本」不需要数据库；JSON 让 App Intent 在后台写入时完全避开 SwiftData 的 `ModelContext` 线程约束，代码量也小。
- **并发**：写入全部收在 `actor LedgerStore`；界面状态在 `@MainActor LedgerModel`；`Entry`、`LedgerCategory` 都是 `Sendable` 值类型。
- **App Intent 后台运行**：`QuickAddIntent.openAppWhenRun = false`，因此落账不打断你正在做的事；App 在前台时靠 `NotificationCenter` 刷新，不在前台则冷启动时 `.task` 里 reload。
- **自动/手动**：`LedgerModel.autoMode` 存在 `UserDefaults`；手动模式对应快捷指令里的「记一笔（确认）」。
- **Siri**：`AppShortcutsProvider` 里注册了「用 Money 记一笔」，可以直接对 Siri 说。
- **分类扩展**：`LedgerCategory.builtins` 加一项（id、kind、emoji、颜色、关键词）即可，界面自动出现。

## 已知取舍

- 没有 App 图标资源：自己拖一张 1024×1024 到 `Assets.xcassets/AppIcon`。
- 没有单元测试：`QuickAddParser.parse` 是纯函数，最适合先补测试（示例输入见根 README 第 6 节）。
- App Intent 首次出现在「快捷指令」里，可能需要先运行一次 App 或重启「快捷指令」。
- 如果 Siri 短语不出现：在 Xcode Signing & Capabilities 里加一次 Siri capability 再试。
- 免费签名 7 天过期，重装会丢本地数据（数据在 App 沙盒里）。要长期用建议付费开发者账号，或先导出 CSV。
