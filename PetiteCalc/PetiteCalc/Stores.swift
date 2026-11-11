//
//  Stores.swift
//  PetiteCalc
//
//  설정과 계산 기록. 앱을 껐다 켜도 유지되도록 UserDefaults에 저장.
//

import SwiftUI
import Observation

// MARK: - 설정

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "시스템 설정"
        case .light: "라이트"
        case .dark: "다크"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var angleUnit: AngleUnit { didSet { defaults.set(angleUnit.rawValue, forKey: "angleUnit") } }
    /// -1 = 자동
    var fractionDigits: Int { didSet { defaults.set(fractionDigits, forKey: "fractionDigits") } }
    var grouping: Bool { didSet { defaults.set(grouping, forKey: "grouping") } }
    var appearance: Appearance { didSet { defaults.set(appearance.rawValue, forKey: "appearance") } }
    var haptics: Bool { didSet { defaults.set(haptics, forKey: "haptics") } }
    var sound: Bool { didSet { defaults.set(sound, forKey: "sound") } }

    static let fractionOptions = [-1, 0, 2, 4, 6]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        angleUnit = AngleUnit(rawValue: defaults.string(forKey: "angleUnit") ?? "") ?? .deg
        fractionDigits = defaults.object(forKey: "fractionDigits") as? Int ?? -1
        grouping = defaults.object(forKey: "grouping") as? Bool ?? true
        appearance = Appearance(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .system
        haptics = defaults.object(forKey: "haptics") as? Bool ?? true
        sound = defaults.object(forKey: "sound") as? Bool ?? false
    }

    var numberStyle: NumberStyle {
        NumberStyle(grouping: grouping, fractionDigits: fractionDigits < 0 ? nil : fractionDigits)
    }

    static func fractionTitle(_ n: Int) -> String {
        n < 0 ? "자동" : "\(n)자리"
    }
}

// MARK: - 계산 기록

struct HistoryEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    let expression: String
    let result: Decimal
    let date: Date
}

@Observable
final class HistoryStore {
    static let limit = 10
    private let defaults: UserDefaults
    private let key = "history"

    private(set) var entries: [HistoryEntry] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            entries = saved
        }
    }

    /// 최근 계산을 맨 위에 추가, 10개 넘으면 오래된 것부터 삭제
    func add(expression: String, result: Decimal, date: Date = .now) {
        entries.insert(HistoryEntry(expression: expression, result: result, date: date), at: 0)
        if entries.count > Self.limit { entries.removeLast(entries.count - Self.limit) }
        save()
    }

    func clear() {
        entries = []
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: key)
        }
    }

    /// 날짜별 묶음: 오늘 / 어제 / 11월 8일
    var sections: [(title: String, items: [HistoryEntry])] {
        let calendar = Calendar.current
        var result: [(String, [HistoryEntry])] = []
        for entry in entries {
            let title: String
            if calendar.isDateInToday(entry.date) {
                title = "오늘"
            } else if calendar.isDateInYesterday(entry.date) {
                title = "어제"
            } else {
                let c = calendar.dateComponents([.month, .day], from: entry.date)
                title = "\(c.month ?? 0)월 \(c.day ?? 0)일"
            }
            if let last = result.last, last.0 == title {
                result[result.count - 1].1.append(entry)
            } else {
                result.append((title, [entry]))
            }
        }
        return result
    }
}
