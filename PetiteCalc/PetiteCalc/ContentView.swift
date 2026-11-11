//
//  ContentView.swift
//  PetiteCalc
//
//  피그마 03 Basic Calculator 화면 (모양 단계 — 계산 기능은 다음 단계)
//

import SwiftUI

struct ContentView: View {
    @State private var mode: CalcMode = .basic

    private let rows: [[CalcKey]] = [
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

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 6)

                Spacer(minLength: 0)

                DisplayView(expression: "1,200 + 34.5", result: "1,234.5")
                    .padding(.bottom, 20)

                keypad
                    .padding(.bottom, 6)
            }
            .padding(.horizontal, Theme.sidePadding)
        }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                IconButton(imageName: "IconHistory")
                Spacer()
                IconButton(imageName: "IconSettings")
            }
            ModeToggle(mode: $mode)
        }
    }

    private var keypad: some View {
        GeometryReader { geo in
            let unit = (geo.size.width - Theme.keySpacing * 3) / 4
            VStack(spacing: Theme.keySpacing) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: Theme.keySpacing) {
                        ForEach(rows[r]) { key in
                            KeyButton(key: key, width: key.isWide ? unit * 2 + Theme.keySpacing : unit)
                        }
                    }
                }
            }
        }
        .frame(height: Theme.keyHeight * 5 + Theme.keySpacing * 4)
    }
}

#Preview {
    ContentView()
}
