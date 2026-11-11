//
//  ContentView.swift
//  PetiteCalc
//
//  메인 화면: 피그마 03 기본 / 04 공학 계산기 (+ 07 복사, 08 오류 표시)
//  위쪽 버튼으로 05 기록, 06 설정 화면을 띄움.
//  앱을 켜면 01 시작 화면, 처음 한 번은 02 안내 화면이 먼저 나옴.
//

import SwiftUI
import AudioToolbox

struct ContentView: View {
    @State private var mode: CalcMode = .basic
    @State private var calculator = Calculator()
    @State private var settings = AppSettings()
    @State private var history = HistoryStore()
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var haptic = UIImpactFeedbackGenerator(style: .light)
    @State private var showSplash = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var showCopyMenu = false
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var onboardingStartPage = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 6)

                Spacer(minLength: 0)

                DisplayView(
                    expression: calculator.expression,
                    result: calculator.displayText,
                    isError: calculator.errorMessage != nil
                )
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.4) {
                    haptic.impactOccurred()
                    withAnimation(.snappy(duration: 0.2)) { showCopyMenu = true }
                }
                .anchorPreference(key: DisplayBoundsKey.self, value: .bounds) { $0 }
                .padding(.bottom, 20)

                Group {
                    if mode == .basic { basicKeypad } else { scientificKeypad }
                }
                .padding(.bottom, 6)
                .transition(.opacity)
            }
            .padding(.horizontal, Theme.sidePadding)
            .animation(.snappy(duration: 0.25), value: mode)

            // 07 복사 메뉴: 바깥을 누르면 닫힘
            if showCopyMenu {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showCopyMenu = false } }
            }
        }
        .overlayPreferenceValue(DisplayBoundsKey.self) { anchor in
            GeometryReader { geo in
                if showCopyMenu, let anchor {
                    let rect = geo[anchor]
                    CopyMenu(onCopy: copyResult, onPaste: pasteNumber)
                        .position(x: rect.maxX - 82, y: rect.minY - 28)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastView(message: toast, showsCopyIcon: toast.contains("복사"))
                    .padding(.top, 58)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay {
            if showOnboarding {
                OnboardingView(startPage: onboardingStartPage) {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    withAnimation(.easeOut(duration: 0.3)) { showOnboarding = false }
                }
                .transition(.opacity)
            }
        }
        .overlay {
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .task {
                        try? await Task.sleep(for: .seconds(1.3))
                        withAnimation(.easeOut(duration: 0.4)) { showSplash = false }
                    }
            }
        }
        .preferredColorScheme(settings.appearance.colorScheme)
        .fullScreenCover(isPresented: $showHistory) {
            HistoryView(history: history, style: settings.numberStyle) { value in
                calculator.recall(value)
                showHistory = false
            } onClose: {
                showHistory = false
            }
            .preferredColorScheme(settings.appearance.colorScheme)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(settings: settings) { showSettings = false }
                .preferredColorScheme(settings.appearance.colorScheme)
        }
        .onAppear(perform: setUp)
        .onChange(of: settings.numberStyle) { _, style in calculator.style = style }
        .onChange(of: settings.angleUnit) { _, unit in calculator.angleUnit = unit }
    }

    private func setUp() {
        calculator.style = settings.numberStyle
        calculator.angleUnit = settings.angleUnit
        calculator.onEvaluate = { [history] expression, result in
            history.add(expression: expression, result: result)
        }
        #if DEBUG
        applyDebugArguments()
        #endif
    }

    // MARK: 07 복사 · 붙여넣기

    private func copyResult() {
        if let text = calculator.copyText {
            UIPasteboard.general.string = text
            showToast("결과를 복사했어요")
        }
        withAnimation { showCopyMenu = false }
    }

    private func pasteNumber() {
        withAnimation { showCopyMenu = false }
        let text = UIPasteboard.general.string ?? ""
        withAnimation(.snappy(duration: 0.2)) {
            if calculator.paste(text) {
                showToast("붙여넣었어요")
            } else {
                showToast("숫자만 붙여넣을 수 있어요")
            }
        }
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        withAnimation(.snappy(duration: 0.25)) { toast = message }
        toastTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { toast = nil }
        }
    }

    private func press(_ label: String) {
        if settings.haptics { haptic.impactOccurred() }
        if settings.sound { AudioServicesPlaySystemSound(1104) }
        withAnimation(.snappy(duration: 0.2)) {
            calculator.press(label)
        }
    }

    // MARK: 위쪽 버튼

    private var topBar: some View {
        ZStack {
            HStack {
                IconButton(imageName: "IconHistory") { showHistory = true }
                    .accessibilityLabel("계산 기록")
                Spacer()
                IconButton(imageName: "IconSettings") { showSettings = true }
                    .accessibilityLabel("설정")
            }
            ModeToggle(mode: $mode)
        }
    }

    // MARK: 기본 키패드 (4줄 × 4칸)

    private let basicRows: [[CalcKey]] = [
        [.init(label: "AC", type: .function), .init(label: "±", type: .function),
         .init(label: "%", type: .function), .init(label: "÷", type: .operation)],
        [.init(label: "7", type: .number), .init(label: "8", type: .number),
         .init(label: "9", type: .number), .init(label: "×", type: .operation)],
        [.init(label: "4", type: .number), .init(label: "5", type: .number),
         .init(label: "6", type: .number), .init(label: "−", type: .operation)],
        [.init(label: "1", type: .number), .init(label: "2", type: .number),
         .init(label: "3", type: .number), .init(label: "+", type: .operation)],
        [.init(label: "0", type: .number, isWide: true), .init(label: ".", type: .number),
         .init(label: "=", type: .equals)],
    ]

    private var basicKeypad: some View {
        keypad(rows: basicRows, columns: 4, metrics: { _ in .basic })
    }

    // MARK: 공학 키패드 (5칸)

    private var scientificRows: [[CalcKey]] {
        let second = calculator.isSecond
        func sci(_ normal: String, _ alt: String? = nil) -> CalcKey {
            CalcKey(label: second ? (alt ?? normal) : normal, type: .scientific)
        }
        return [
            [sci("2nd"), sci(calculator.angleUnit.rawValue), sci("sin", "sin⁻¹"), sci("cos", "cos⁻¹"), sci("tan", "tan⁻¹")],
            [sci("x²", "x³"), sci("xʸ"), sci("√", "∛"), sci("ln", "eˣ"), sci("log", "10ˣ")],
            [sci("("), sci(")"), sci("π"), sci("e"), sci("x!")],
            [.init(label: "AC", type: .function), .init(label: "±", type: .function),
             .init(label: "%", type: .function), .init(label: "1/x", type: .function),
             .init(label: "÷", type: .operation)],
            [.init(label: "7", type: .number), .init(label: "8", type: .number),
             .init(label: "9", type: .number), .init(label: "mc", type: .function),
             .init(label: "×", type: .operation)],
            [.init(label: "4", type: .number), .init(label: "5", type: .number),
             .init(label: "6", type: .number), .init(label: "mr", type: .function),
             .init(label: "−", type: .operation)],
            [.init(label: "1", type: .number), .init(label: "2", type: .number),
             .init(label: "3", type: .number), .init(label: second ? "m−" : "m+", type: .function),
             .init(label: "+", type: .operation)],
            [.init(label: "0", type: .number, isWide: true), .init(label: ".", type: .number),
             .init(label: "EE", type: .function), .init(label: "=", type: .equals)],
        ]
    }

    private var scientificKeypad: some View {
        keypad(rows: scientificRows, columns: 5, metrics: { row in row < 3 ? .scientificTop : .scientific })
    }

    // MARK: 공통 키패드 배치

    private func keypad(rows: [[CalcKey]], columns: Int, metrics: @escaping (Int) -> KeyMetrics) -> some View {
        let spacing = Theme.keySpacing
        let height = rows.indices.reduce(CGFloat(0)) { $0 + metrics($1).height } + spacing * CGFloat(rows.count - 1)
        return GeometryReader { geo in
            let unit = (geo.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            VStack(spacing: spacing) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(rows[r]) { key in
                            KeyButton(
                                key: key,
                                width: key.isWide ? unit * 2 + spacing : unit,
                                metrics: metrics(r),
                                isActive: key.label == "2nd" && calculator.isSecond
                            ) {
                                press(key.label)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: height)
    }

    // MARK: 확인용 실행 인자 (DEBUG 전용)

    #if DEBUG
    /// -keys "1200+34.5=" 또는 "3 0 sin + 1 6 √ =" / -mode scientific / -show history|settings
    private func applyDebugArguments() {
        let args = CommandLine.arguments
        func value(_ flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        if args.contains("-skipIntro") { showSplash = false; showOnboarding = false }
        if args.contains("-onboarding") {
            showSplash = false
            showOnboarding = true
            onboardingStartPage = Int(value("-onboarding") ?? "") ?? 0
        }
        if value("-mode") == "scientific" { mode = .scientific }
        if let keys = value("-keys") {
            let list = keys.contains(" ") ? keys.split(separator: " ").map(String.init) : keys.map { String($0) }
            list.forEach { calculator.press($0) }
        }
        switch value("-show") {
        case "history": showHistory = true
        case "settings": showSettings = true
        case "copy":
            showCopyMenu = true
            showToast("결과를 복사했어요")
        default: break
        }
    }
    #endif
}

/// 결과 숫자 영역의 위치 (복사 메뉴를 그 위에 띄우려고)
private struct DisplayBoundsKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

#Preview {
    ContentView()
}
