//
//  CalculatorComponents.swift
//  PetiteCalc
//
//  피그마 컴포넌트: Key, Display, Mode Toggle, Icon Button
//

import SwiftUI

// MARK: - Key

enum KeyType {
    case number, function, operation, equals
}

struct CalcKey: Identifiable {
    let label: String
    let type: KeyType
    var isWide = false
    var id: String { label }
}

struct KeyButton: View {
    let key: CalcKey
    let width: CGFloat
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(key.label)
                .font(font)
                .tracking(tracking)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: key.isWide ? .leading : .center)
                .padding(.leading, key.isWide ? 30 : 0)
                .frame(width: width, height: Theme.keyHeight)
        }
        .buttonStyle(GlassKeyStyle(type: key.type))
    }

    private var font: Font {
        switch key.type {
        case .number: AppFont.keyNumber
        case .function: AppFont.keyFunction
        case .operation, .equals: AppFont.keyOperator
        }
    }

    private var tracking: CGFloat {
        switch key.type {
        case .number: -0.3
        case .function: -0.24
        case .operation, .equals: 0
        }
    }

    private var textColor: Color {
        switch key.type {
        case .number, .function: Theme.textPrimary
        case .operation, .equals: Theme.textOnAccent
        }
    }
}

/// 유리 버튼 스타일 — 누르면 밝아지고 그림자가 사라지며 94%로 작아짐
struct GlassKeyStyle: ButtonStyle {
    let type: KeyType

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: Theme.keyRadius, style: .continuous)

        configuration.label
            .background {
                ZStack {
                    switch type {
                    case .number: shape.fill(Theme.keyNumber)
                    case .function: shape.fill(Theme.keyFunction)
                    case .operation: shape.fill(Theme.keyOperator)
                    case .equals: shape.fill(Theme.keyEquals)
                    }
                    if pressed { shape.fill(Color.white.opacity(0.25)) }
                }
            }
            .overlay { shape.strokeBorder(Theme.keyBorder, lineWidth: 1) }
            .shadow(color: pressed ? .clear : Theme.keyShadow, radius: 8, x: 0, y: 6)
            .scaleEffect(pressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

// MARK: - Display

struct DisplayView: View {
    let expression: String
    let result: String
    var isError = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // 비어 있어도 줄 높이는 유지해서 숫자가 위아래로 튀지 않게
            Text(expression.isEmpty ? " " : expression)
                .font(AppFont.displayExpression)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if isError {
                Text(result)
                    .font(AppFont.displayError)
                    .tracking(-0.9)
                    .foregroundStyle(Theme.textError)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            } else {
                Text(result)
                    .font(AppFont.displayResult)
                    .tracking(-1.92)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Mode Toggle

enum CalcMode: String, CaseIterable {
    case basic = "기본"
    case scientific = "공학"
}

struct ModeToggle: View {
    @Binding var mode: CalcMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(CalcMode.allCases, id: \.self) { item in
                let active = item == mode
                Button {
                    mode = item
                } label: {
                    Text(item.rawValue)
                        .font(AppFont.toggleLabel)
                        .foregroundStyle(active ? Theme.textOnAccent : Theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background {
                            if active { Capsule().fill(Theme.toggleActive) }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Theme.toggleTrack))
        .overlay(Capsule().strokeBorder(Theme.keyBorder, lineWidth: 1))
        .animation(.easeOut(duration: 0.15), value: mode)
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let imageName: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Theme.keyFunction))
                .overlay(Circle().strokeBorder(Theme.keyBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
