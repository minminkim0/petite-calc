//
//  IntroViews.swift
//  PetiteCalc
//
//  피그마 01 Launch(시작 화면), 02 Onboarding(첫 실행 안내),
//  07 Copy Result(복사 메뉴·알림) 부품.
//

import SwiftUI

// MARK: - 01 Launch

struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Image("LaunchIcon")
                    .resizable()
                    .frame(width: 210, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 46.667, style: .continuous))
                    .padding(.bottom, 34)
                Text("Petite Calc")
                    .font(AppFont.jakarta(32, .heavy))
                    .tracking(-0.96)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.bottom, 10)
                Text("오늘의 계산도\n예쁘고 똑 부러지게!")
                    .font(AppFont.korean(17, .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .offset(y: -10)
        }
    }
}

// MARK: - 02 Onboarding

struct OnboardingView: View {
    var startPage = 0
    var onFinish: () -> Void
    @State private var page = 0

    private let pages: [(title: String, body: String)] = [
        ("기본과 공학을\n한 번에",
         "위쪽 버튼을 누르면 기본 계산기와 공학용 계산기를\n바로 오갈 수 있어요. 인터넷이 없어도 그대로 쓸 수 있어요."),
        ("지난 계산도\n한눈에",
         "왼쪽 위 시계 버튼에 최근 계산 10개가 남아요.\n누르면 그 결과를 바로 다시 쓸 수 있어요."),
        ("길게 눌러\n복사하기",
         "결과 숫자를 길게 누르면 복사하거나 붙여넣을 수 있어요.\n설정에서 다크 모드도 고를 수 있어요."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("건너뛰기", action: onFinish)
                        .font(AppFont.korean(14, .bold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .frame(height: 40)

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        OnboardingPage(index: i, title: pages[i].title, message: pages[i].body)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .task(id: startPage) { page = startPage }

                PageDots(count: pages.count, current: page)
                    .padding(.bottom, 73)

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "다음" : "시작하기")
                        .font(AppFont.korean(17, .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(Theme.keyEquals))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.sidePadding)
                .padding(.bottom, 10)
            }
        }
    }
}

private struct OnboardingPage: View {
    let index: Int
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            illustration
                .frame(width: 300, height: 260)
                .glassCard(radius: 32)
                .shadow(color: Theme.keyShadow, radius: 8, x: 0, y: 6)
                .padding(.top, 56)
                .padding(.bottom, 38)

            Text(title)
                .font(AppFont.korean(28, .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.bottom, 22)

            Text(message)
                .font(AppFont.korean(14, .regular))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var illustration: some View {
        switch index {
        case 0:
            VStack(spacing: 50) {
                // 1.5배 크기 모드 토글
                HStack(spacing: 6) {
                    Text("기본")
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 24).padding(.vertical, 10.5)
                    Text("공학")
                        .foregroundStyle(Theme.toggleActiveText)
                        .padding(.horizontal, 24).padding(.vertical, 10.5)
                        .background(Capsule().fill(Theme.toggleActive))
                }
                .font(AppFont.korean(18, .bold))
                .padding(4.5)
                .background(Capsule().fill(Theme.toggleTrack))
                .overlay(Capsule().strokeBorder(Theme.keyBorder, lineWidth: 1.5))

                HStack(spacing: 10) {
                    sampleKey("sin", .scientific, radius: 14, size: 14)
                    sampleKey("√", .scientific, radius: 14, size: 14)
                    sampleKey("+", .operation, radius: 22, size: 28)
                    sampleKey("=", .equals, radius: 22, size: 28)
                }
            }
        case 1:
            VStack(spacing: 10) {
                sampleHistory("1,200 + 34.5", "1,234.5")
                sampleHistory("sin(30°) + √16", "4.5")
            }
            .padding(.horizontal, 24)
        default:
            VStack(alignment: .trailing, spacing: 14) {
                CopyMenu(onCopy: {}, onPaste: {})
                    .allowsHitTesting(false)
                Text("1,234.5")
                    .font(AppFont.jakarta(48, .semibold))
                    .tracking(-1.4)
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 30)
        }
    }

    private func sampleKey(_ label: String, _ type: KeyType, radius: CGFloat, size: CGFloat) -> some View {
        KeyButton(
            key: CalcKey(label: label, type: type),
            width: 52,
            metrics: KeyMetrics(height: 52, radius: radius, numberSize: size, functionSize: size, operatorSize: size)
        )
        .allowsHitTesting(false)
    }

    private func sampleHistory(_ expression: String, _ result: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(expression)
                .font(AppFont.jakarta(12, .medium))
                .foregroundStyle(Theme.textSecondary)
            Text(result)
                .font(AppFont.jakarta(22, .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .glassCard(radius: 18)
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Theme.textPrimary : Theme.textPrimary.opacity(0.2))
                    .frame(width: i == current ? 22 : 7, height: 7)
            }
        }
        .animation(.snappy(duration: 0.2), value: current)
    }
}

// MARK: - 07 Copy Result

/// 결과를 길게 누르면 뜨는 메뉴 (복사 | 붙여넣기)
struct CopyMenu: View {
    var onCopy: () -> Void
    var onPaste: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onCopy) {
                HStack(spacing: 6) {
                    Image("IconCopy")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text("복사")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
            }
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1)
            Button(action: onPaste) {
                Text("붙여넣기")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
            }
        }
        .buttonStyle(.plain)
        .font(AppFont.korean(14, .bold))
        .foregroundStyle(.white)
        .fixedSize()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.menuBackground))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.keyBorder.opacity(0.6), lineWidth: 1))
        .shadow(color: Theme.keyShadow, radius: 8, x: 0, y: 6)
    }
}

/// 위쪽에 잠깐 뜨는 알림 ("결과를 복사했어요")
struct ToastView: View {
    let message: String
    var showsCopyIcon = true

    var body: some View {
        HStack(spacing: 8) {
            if showsCopyIcon {
                Image("IconCopy")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 16, height: 16)
            }
            Text(message)
                .font(AppFont.korean(14, .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Capsule().fill(.ultraThinMaterial))
        .background(Capsule().fill(Theme.keyNumber))
        .overlay(Capsule().strokeBorder(Theme.keyBorder, lineWidth: 1))
        .shadow(color: Theme.keyShadow, radius: 8, x: 0, y: 6)
    }
}
