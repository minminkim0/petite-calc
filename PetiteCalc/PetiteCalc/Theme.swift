//
//  Theme.swift
//  PetiteCalc
//
//  피그마 "Pastel Glass" 색·크기·글꼴.
//  다크 모드 색은 피그마에 없어서 같은 톤(보라·핑크·민트)을 밤 버전으로 맞춤.
//

import SwiftUI
import UIKit
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

    /// 라이트/다크 모드에 따라 자동으로 바뀌는 색
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

enum Theme {
    // 배경 그라디언트
    static let background = LinearGradient(
        stops: [
            .init(color: Color(light: Color(hex: 0xFCE3EC), dark: Color(hex: 0x2A1E36)), location: 0),
            .init(color: Color(light: Color(hex: 0xE6E4FB), dark: Color(hex: 0x1F1C38)), location: 0.35),
            .init(color: Color(light: Color(hex: 0xDDF0F7), dark: Color(hex: 0x14263A)), location: 0.78),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // 글자
    static let textPrimary = Color(light: Color(hex: 0x2F2A45), dark: Color(hex: 0xF3F0FF))
    static let textSecondary = Color(light: Color(hex: 0x807A9C), dark: Color(hex: 0xA9A2CC))
    static let textScientific = Color(light: Color(hex: 0x4A4466), dark: Color(hex: 0xD6D0F2))
    static let textOnAccent = Color.white
    static let textError = Color(light: Color(hex: 0xD9467A), dark: Color(hex: 0xFF7DAA))
    static let textAccent = Color(light: Color(hex: 0x7C6CF2), dark: Color(hex: 0xA99DFF))

    // 유리 버튼
    static let keyNumber = Color(light: .white.opacity(0.55), dark: .white.opacity(0.10))
    static let keyFunction = Color(light: .white.opacity(0.32), dark: .white.opacity(0.06))
    static let keyScientific = Color(light: .white.opacity(0.38), dark: .white.opacity(0.07))
    static let keyBorder = Color(light: .white.opacity(0.75), dark: .white.opacity(0.16))
    static let keyPressedOverlay = Color(light: .white.opacity(0.25), dark: .white.opacity(0.12))
    static let keyOperator = Color(hex: 0x7C6CF2)
    static let keyEquals = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x8E7CF7), location: 0.146),
            .init(color: Color(hex: 0xF08BB4), location: 0.854),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let keyShadow = Color(light: Color(hex: 0x50468C, opacity: 0.10), dark: .black.opacity(0.30))

    // 모드 토글 · 켜진 버튼(2nd)
    static let toggleTrack = Color(light: .white.opacity(0.45), dark: .white.opacity(0.08))
    static let toggleActive = Color(light: Color(hex: 0x2F2A45), dark: Color(hex: 0xF3F0FF))
    static let toggleActiveText = Color(light: .white, dark: Color(hex: 0x2F2A45))

    // 복사 메뉴
    static let menuBackground = Color(light: Color(hex: 0x2F2A45), dark: Color(hex: 0x3B3558))

    // 설정 목록 구분선
    static let separator = Color(light: Color(hex: 0x2F2A45, opacity: 0.08), dark: .white.opacity(0.08))

    static let sidePadding: CGFloat = 20
    static let keySpacing: CGFloat = 11
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

    /// 한글: Noto Sans KR 대신 시스템 한글 글꼴
    static func korean(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight)
    }

    static let displayExpression = jakarta(17, .medium)
    static let displayResult = jakarta(64, .semibold)
    static let displayError = korean(30, .bold)
    static let toggleLabel = korean(12, .bold)
}
