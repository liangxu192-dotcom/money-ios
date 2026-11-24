import Foundation
import SwiftUI
import UIKit

extension Color {
    /// "#FF9500" → Color
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        if cleaned.count == 6 {
            self.init(
                red: Double((value & 0xFF0000) >> 16) / 255,
                green: Double((value & 0x00FF00) >> 8) / 255,
                blue: Double(value & 0x0000FF) / 255
            )
        } else {
            self.init(white: 0.5)
        }
    }
}

/// 卡片样式：圆角白底、内边距、浅阴影。
struct CardBackground: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }
}

/// 分类图标：emoji + 淡色底。
struct CategoryBadge: View {
    var category: LedgerCategory
    var size: CGFloat = 38

    var body: some View {
        Text(category.emoji)
            .font(.system(size: size * 0.46))
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(Color(hex: category.colorHex).opacity(0.14))
            )
    }
}

/// 一笔流水的行。
struct EntryRow: View {
    var entry: Entry
    var category: LedgerCategory

    var body: some View {
        HStack(spacing: 11) {
            CategoryBadge(category: category)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.note.isEmpty ? category.name : entry.note)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text(category.name)
                    Text("·")
                    Text(entry.date, format: .dateTime.hour().minute())
                    Text(entry.source.title)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(
                                entry.source == .auto
                                    ? Color.blue.opacity(0.12)
                                    : Color(uiColor: .tertiarySystemFill)
                            )
                        )
                        .foregroundStyle(entry.source == .auto ? Color.blue : Color.secondary)
                }
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 6)

            Text(entry.signedAmount)
                .font(.system(size: 15, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(entry.kind == .income ? Color.green : Color.primary)
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }
}

struct ToastView: View {
    var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.footnote.weight(.medium))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}
