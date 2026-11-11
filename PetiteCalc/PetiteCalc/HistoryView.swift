//
//  HistoryView.swift
//  PetiteCalc
//
//  피그마 05 History. 최근 10개 계산, 누르면 그 결과를 계산기로 불러옴.
//

import SwiftUI

struct HistoryView: View {
    let history: HistoryStore
    let style: NumberStyle
    var onSelect: (Decimal) -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeader(title: "계산 기록", onClose: onClose)

                if history.entries.isEmpty {
                    Spacer()
                    Text("아직 계산 기록이 없어요")
                        .font(AppFont.korean(15, .regular))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(history.sections, id: \.title) { section in
                                SectionLabel(text: section.title)
                                ForEach(section.items) { item in
                                    Button {
                                        onSelect(item.result)
                                    } label: {
                                        HistoryRow(item: item, style: style)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.sidePadding)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                    }
                    .scrollIndicators(.hidden)

                    Button {
                        withAnimation { history.clear() }
                    } label: {
                        Text("기록 지우기")
                            .font(AppFont.korean(16, .bold))
                            .foregroundStyle(Theme.textAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .glassCard(radius: 28)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Theme.sidePadding)
                    .padding(.bottom, 6)
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let item: HistoryEntry
    let style: NumberStyle

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(item.expression)
                .font(AppFont.jakarta(14, .medium))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(Calculator.format(item.result, style: style))
                .font(AppFont.jakarta(28, .semibold))
                .tracking(-0.56)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassCard()
        .contentShape(Rectangle())
    }
}
