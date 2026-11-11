//
//  SettingsView.swift
//  PetiteCalc
//
//  피그마 06 Settings + 화면 모드(다크 모드) 추가
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var onClose: () -> Void
    @State private var showPrivacy = false

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeader(title: "설정", onClose: onClose)

                ScrollView {
                    VStack(spacing: 10) {
                        SectionLabel(text: "계산")
                        SettingsGroup {
                            MenuRow(title: "각도 단위 기본값", value: settings.angleUnit == .deg ? "Deg" : "Rad") {
                                Picker("각도 단위", selection: $settings.angleUnit) {
                                    Text("Deg (도)").tag(AngleUnit.deg)
                                    Text("Rad (라디안)").tag(AngleUnit.rad)
                                }
                            }
                            RowDivider()
                            MenuRow(title: "소수점 자리", value: AppSettings.fractionTitle(settings.fractionDigits)) {
                                Picker("소수점 자리", selection: $settings.fractionDigits) {
                                    ForEach(AppSettings.fractionOptions, id: \.self) { n in
                                        Text(AppSettings.fractionTitle(n)).tag(n)
                                    }
                                }
                            }
                            RowDivider()
                            ToggleRow(title: "천 단위 쉼표", isOn: $settings.grouping)
                        }

                        SectionLabel(text: "화면").padding(.top, 8)
                        SettingsGroup {
                            MenuRow(title: "화면 모드", value: settings.appearance.title) {
                                Picker("화면 모드", selection: $settings.appearance) {
                                    ForEach(Appearance.allCases) { a in
                                        Text(a.title).tag(a)
                                    }
                                }
                            }
                        }

                        SectionLabel(text: "피드백").padding(.top, 8)
                        SettingsGroup {
                            ToggleRow(title: "진동", isOn: $settings.haptics)
                            RowDivider()
                            ToggleRow(title: "버튼 소리", isOn: $settings.sound)
                        }

                        SectionLabel(text: "정보").padding(.top, 8)
                        SettingsGroup {
                            SettingRow(title: "버전") {
                                Text(version)
                                    .font(AppFont.jakarta(15, .medium))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            RowDivider()
                            Button { showPrivacy = true } label: {
                                SettingRow(title: "개인정보 처리방침") { Chevron() }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.sidePadding)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyView()
                .presentationDetents([.medium])
        }
    }
}

// MARK: - 행 부품

private struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .glassCard()
    }
}

private struct RowDivider: View {
    var body: some View {
        Rectangle().fill(Theme.separator).frame(height: 1)
    }
}

private struct Chevron: View {
    var body: some View {
        Image("IconChevron")
            .renderingMode(.template)
            .resizable()
            .foregroundStyle(Theme.textSecondary)
            .frame(width: 18, height: 18)
    }
}

private struct SettingRow<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.korean(15, .regular))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            trailing
        }
        .padding(.leading, 18)
        .padding(.trailing, 14)
        .frame(height: 54)
        .contentShape(Rectangle())
    }
}

/// 값 + › 표시, 누르면 고르는 메뉴가 뜸
private struct MenuRow<Options: View>: View {
    let title: String
    let value: String
    @ViewBuilder var options: Options

    var body: some View {
        Menu {
            options
        } label: {
            SettingRow(title: title) {
                HStack(spacing: 4) {
                    Text(value)
                        .font(AppFont.korean(15, .regular))
                        .foregroundStyle(Theme.textSecondary)
                    Chevron()
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        SettingRow(title: title) {
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(Theme.keyOperator)
        }
    }
}

// MARK: - 개인정보 처리방침

private struct PrivacyView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text("개인정보 처리방침")
                    .font(AppFont.korean(20, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Petite Calc은 어떤 개인정보도 수집하지 않아요.\n\n계산 기록과 설정은 이 기기 안에만 저장되고, 인터넷으로 보내지지 않아요. 앱을 지우면 함께 지워져요.")
                    .font(AppFont.korean(15, .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(4)
                Spacer()
            }
            .padding(24)
            .padding(.top, 8)
        }
    }
}
