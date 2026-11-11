//
//  Theme.swift
//  PetiteCalc
//
//  피그마 "Pastel Glass" 변수와 텍스트 스타일을 옮긴 것.
//

import SwiftUI
import CoreText

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum Theme {
    // 배경 그라디언트
    static let background = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xFCE3EC), location: 0),
            .init(color: Color(hex: 0xE6E4FB), location: 0.35),
            .init(color: Color(hex: 0xDDF0F7), location: 0.78),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // 글자
    static let textPrimary = Color(hex: 0x2F2A45)
    static let textSecondary = Color(hex: 0x807A9C)
    static let textOnAccent = Color.white
    static let textError = Color(hex: 0xD9467A)

    // 유리 버튼
    static let keyNumber = Color.white.opacity(0.55)
    static let keyFunction = Color.white.opacity(0.32)
    static let keyBorder = Color.white.opacity(0.75)
    static let keyOperator = Color(hex: 0x7C6CF2)
    static let keyEquals = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x8E7CF7), location: 0.146),
            .init(color: Color(hex: 0xF08BB4), location: 0.854),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let keyShadow = Color(hex: 0x50468C, opacity: 0.10)

    // 모드 토글
    static let toggleTrack = Color.white.opacity(0.45)
    static let toggleActive = Color(hex: 0x2F2A45)

    // 크기
    static let keyRadius: CGFloat = 22
    static let keySpacing: CGFloat = 11
    static let keyHeight: CGFloat = 76
    static let sidePadding: CGFloat = 20
}

// MARK: - 글꼴

enum AppFont {
    static let family = "Plus Jakarta Sans"

    /// 앱 번들에 넣은 글꼴을 등록 (Info.plist 수정 없이)
    static func register() {
        guard let url = Bundle.main.url(forResource: "PlusJakartaSans", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    static func jakarta(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .custom(family, fixedSize: size).weight(weight)
    }

    static let displayExpression = jakarta(17, .medium)
    static let displayResult = jakarta(64, .semibold)
    static let keyNumber = jakarta(30, .semibold)
    static let keyFunction = jakarta(24, .semibold)
    static let keyOperator = jakarta(36, .semibold)
    // 한글 토글 라벨: Noto Sans KR 대신 시스템 한글 글꼴(굵게) 사용
    static let toggleLabel = Font.system(size: 12, weight: .bold)
    static let displayError = Font.system(size: 30, weight: .bold)
}
