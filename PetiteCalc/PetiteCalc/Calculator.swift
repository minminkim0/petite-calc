//
//  Calculator.swift
//  PetiteCalc
//
//  기본 계산기 로직. 아이폰 기본 계산기처럼 입력 순서대로 계산한다.
//  정확도를 위해 Double 대신 Decimal 사용 (0.1 + 0.2 = 0.3).
//

import Foundation
import Observation

enum Operation: String {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
    case divide = "÷"
}

@Observable
final class Calculator {
    /// 위쪽 작은 줄 (예: "1,200 + 34.5")
    private(set) var expression = ""
    /// 오류가 나면 메시지 (예: "0으로 나눌 수 없어요")
    private(set) var errorMessage: String?

    /// 지금 화면에 보이는 값
    private var value: Decimal = 0
    /// 사용자가 치고 있는 숫자 원문 (끝의 "." 이나 "0"을 살리기 위해)
    private var typing: String?
    private var accumulator: Decimal?
    private var pending: Operation?
    /// 연산 기호 다음에 새 숫자를 넣었는지
    private var rhsEntered = false
    /// "=" 직후인지
    private var justEvaluated = false
    /// "=" 반복용 (5 + 3 = = → 11)
    private var lastOp: (Operation, Decimal)?

    static let maxDigits = 15

    /// 큰 글씨로 보여 줄 문자열
    var displayText: String {
        if let errorMessage { return errorMessage }
        if let typing { return Self.formatTyping(typing) }
        return Self.format(value)
    }

    // MARK: - 버튼

    func press(_ label: String) {
        switch label {
        case "0"..."9": digit(label)
        case ".": decimalPoint()
        case "AC": clear()
        case "±": negate()
        case "%": percent()
        case "=": equals()
        default:
            if let op = Operation(rawValue: label) { operation(op) }
        }
    }

    func digit(_ d: String) {
        if errorMessage != nil { clear() }
        startFreshIfNeeded()
        var t = typing ?? ""
        if t.filter(\.isNumber).count >= Self.maxDigits { return }
        switch t {
        case "", "0": t = d
        case "-0": t = "-" + d
        default: t += d
        }
        setTyping(t)
    }

    func decimalPoint() {
        if errorMessage != nil { clear() }
        startFreshIfNeeded()
        guard let t = typing else { setTyping("0."); return }
        if !t.contains(".") { setTyping(t + ".") }
    }

    func clear() {
        expression = ""
        errorMessage = nil
        value = 0
        typing = nil
        accumulator = nil
        pending = nil
        rhsEntered = false
        justEvaluated = false
        lastOp = nil
    }

    func negate() {
        guard errorMessage == nil else { return }
        if let t = typing {
            setTyping(t.hasPrefix("-") ? String(t.dropFirst()) : "-" + t)
        } else if pending != nil && !rhsEntered {
            setTyping("-0")
        } else {
            value = -value
        }
    }

    func percent() {
        guard errorMessage == nil else { return }
        // 아이폰 방식: 200 + 10% → 200 + 20
        if let op = pending, let acc = accumulator, op == .add || op == .subtract {
            value = acc * value / 100
        } else {
            value = value / 100
        }
        typing = nil
        rhsEntered = true
    }

    func operation(_ op: Operation) {
        guard errorMessage == nil else { return }
        if justEvaluated {
            justEvaluated = false
            lastOp = nil
            accumulator = value
        } else if let p = pending, let acc = accumulator, rhsEntered {
            // 연속 계산: 2 + 3 × → 5 ×
            guard let r = compute(acc, p, value) else { return }
            accumulator = r
            value = r
        } else if pending == nil {
            accumulator = value
        }
        pending = op
        typing = nil
        rhsEntered = false
        expression = "\(Self.format(accumulator ?? value)) \(op.rawValue)"
    }

    func equals() {
        guard errorMessage == nil else { return }
        let lhs: Decimal
        let op: Operation
        let rhs: Decimal
        if let p = pending, let acc = accumulator {
            lhs = acc; op = p; rhs = value
        } else if justEvaluated, let (p, r) = lastOp {
            lhs = value; op = p; rhs = r
        } else {
            return
        }
        guard let result = compute(lhs, op, rhs) else { return }
        expression = "\(Self.format(lhs)) \(op.rawValue) \(Self.format(rhs))"
        lastOp = (op, rhs)
        pending = nil
        accumulator = result
        value = result
        typing = nil
        rhsEntered = false
        justEvaluated = true
    }

    // MARK: - 내부

    private func setTyping(_ t: String) {
        typing = t
        value = Decimal(string: t) ?? 0
        rhsEntered = true
    }

    /// "=" 직후에 숫자를 누르면 새 계산 시작
    private func startFreshIfNeeded() {
        guard justEvaluated else { return }
        justEvaluated = false
        accumulator = nil
        lastOp = nil
        expression = ""
        typing = nil
    }

    private func compute(_ a: Decimal, _ op: Operation, _ b: Decimal) -> Decimal? {
        let result: Decimal
        switch op {
        case .add: result = a + b
        case .subtract: result = a - b
        case .multiply: result = a * b
        case .divide:
            if b == 0 {
                fail(expression: "\(Self.format(a)) ÷ 0", message: "0으로 나눌 수 없어요")
                return nil
            }
            result = a / b
        }
        if result.isNaN || abs(result) >= Decimal(sign: .plus, exponent: 100, significand: 1) {
            fail(expression: "\(Self.format(a)) \(op.rawValue) \(Self.format(b))", message: "숫자가 너무 커요")
            return nil
        }
        return result
    }

    private func fail(expression: String, message: String) {
        clear()
        self.expression = expression
        errorMessage = message
    }

    // MARK: - 숫자 표시

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.maximumFractionDigits = 10
        return f
    }()

    private static let scientificFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .scientific
        f.maximumSignificantDigits = 10
        f.exponentSymbol = "e"
        return f
    }()

    /// 계산 결과 표시: 소수 10자리에서 반올림, 너무 크거나 작으면 지수 표기
    static func format(_ d: Decimal) -> String {
        var input = d
        var rounded = Decimal()
        NSDecimalRound(&rounded, &input, 10, .plain)
        let magnitude = abs(rounded)
        let useScientific = magnitude >= Decimal(sign: .plus, exponent: 15, significand: 1)
            || (magnitude != 0 && magnitude < Decimal(sign: .plus, exponent: -9, significand: 1))
        let formatter = useScientific ? scientificFormatter : decimalFormatter
        let source = useScientific ? d : rounded
        return formatter.string(from: source as NSDecimalNumber) ?? "\(source)"
    }

    /// 입력 중인 숫자 표시: 천 단위 쉼표만 넣고 끝의 "." / "0"은 그대로
    static func formatTyping(_ t: String) -> String {
        var s = Substring(t)
        let negative = s.hasPrefix("-")
        if negative { s = s.dropFirst() }
        let parts = s.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intPart = String(parts[0])
        var grouped = ""
        for (i, ch) in intPart.reversed().enumerated() {
            if i > 0 && i % 3 == 0 { grouped.append(",") }
            grouped.append(ch)
        }
        var out = (negative ? "-" : "") + String(grouped.reversed())
        if parts.count > 1 { out += "." + parts[1] }
        return out
    }
}
