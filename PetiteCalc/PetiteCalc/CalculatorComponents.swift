//
//  CalculatorComponents.swift
//  PetiteCalc
//
//  피그마 컴포넌트: Key, Display, Mode Toggle, Icon Button
//

import SwiftUI

// MARK: - Key

enum KeyType {
    case number, function, operation, equals, scientific
}

struct CalcKey: Identifiable {
    let label: String
    let type: KeyType
    var isWide = false
    var id: String { label }
}

/// 키 크기·글자 크기 (기본 화면 / 공학 화면)
struct KeyMetrics {
    let height: CGFloat
    let radius: CGFloat
    let numberSize: CGFloat
    let functionSize: CGFloat
    let operatorSize: CGFloat

    static let basic = KeyMetrics(height: 76, radius: 22, numberSize: 30, functionSize: 24, operatorSize: 36)
    static let scientific = KeyMetrics(height: 58, radius: 22, numberSize: 22, functionSize: 18, operatorSize: 28)
    static let scientificTop = KeyMetrics(height: 40, radius: 14, numberSize: 14, functionSize: 14, operatorSize: 14)
}

struct KeyButton: View {
    let key: CalcKey
    let width: CGFloat
    let metrics: KeyMetrics
    var isActive = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(key.label)
                .font(AppFont.jakarta(fontSize, .semibold))
                .tracking(tracking)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: key.isWide ? .leading : .center)
                .padding(.leading, key.isWide ? 30 : 0)
                .frame(width: width, height: metrics.height)
                .contentShape(Rectangle())
        }
        .buttonStyle(GlassKeyStyle(type: key.type, radius: metrics.radius, isActive: isActive))
        .accessibilityLabel(key.label)
    }

    private var fontSize: CGFloat {
        switch key.type {
        case .number: metrics.numberSize
        case .function, .scientific: metrics.functionSize
        case .operation, .equals: metrics.operatorSize
        }
    }

    private var tracking: CGFloat {
        switch key.type {
        case .number, .function: -fontSize / 100
        default: 0
        }
    }

    private var textColor: Color {
        if isActive { return Theme.toggleActiveText }
        switch key.type {
        case .number, .function: return Theme.textPrimary
        case .scientific: return Theme.textScientific
        case .operation, .equals: return Theme.textOnAccent
        }
    }
}

/// 유리 버튼 스타일 — 누르면 밝아지고 그림자가 사라지며 94%로 작아짐
struct GlassKeyStyle: ButtonStyle {
    let type: KeyType
    var radius: CGFloat = 22
    var isActive = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        configuration.label
            .background {
                ZStack {
                    if isActive {
                        shape.fill(Theme.toggleActive)
                    } else {
                        switch type {
                        case .number: shape.fill(Theme.keyNumber)
                        case .function: shape.fill(Theme.keyFunction)
                        case .scientific: shape.fill(Theme.keyScientific)
                        case .operation: shape.fill(Theme.keyOperator)
                        case .equals: shape.fill(Theme.keyEquals)
                        }
                    }
                    if pressed { shape.fill(Theme.keyPressedOverlay) }
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
                        .foregroundStyle(active ? Theme.toggleActiveText : Theme.textSecondary)
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
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Theme.keyFunction))
                .overlay(Circle().strokeBorder(Theme.keyBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// 기록·설정 화면 위쪽: 닫기 버튼 + 가운데 제목
struct ScreenHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(AppFont.korean(18, .bold))
                .foregroundStyle(Theme.textPrimary)
            HStack {
                IconButton(imageName: "IconClose", action: onClose)
                    .accessibilityLabel("닫기")
                Spacer()
            }
        }
        .padding(.horizontal, Theme.sidePadding)
        .padding(.top, 6)
    }
}

/// 기록·설정의 묶음 제목 ("오늘", "계산" …)
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(AppFont.korean(13, .bold))
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 유리 카드 배경
struct GlassCard: ViewModifier {
    var radius: CGFloat = 20
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(shape.fill(Theme.keyNumber))
            .overlay(shape.strokeBorder(Theme.keyBorder, lineWidth: 1))
    }
}

extension View {
    func glassCard(radius: CGFloat = 20) -> some View { modifier(GlassCard(radius: radius)) }
}
