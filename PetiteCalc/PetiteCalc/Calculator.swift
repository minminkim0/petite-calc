//
//  Calculator.swift
//  PetiteCalc
//
//  계산 엔진 (기본 + 공학 공용).
//  - 사칙연산은 계산 순서를 따른다: 2 + 3 × 4 = 14
//  - 괄호, xʸ, EE 지원
//  - sin·√·x² 같은 한 숫자짜리 함수는 누르는 즉시 지금 숫자에 적용 (아이폰 방식)
//  - 정확도를 위해 Decimal 사용 (0.1 + 0.2 = 0.3)
//

import Foundation
import Observation

// MARK: - 기본 타입

enum BinaryOp: String {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
    case divide = "÷"
    case power = "^"
    case ee = "E"

    var precedence: Int {
        switch self {
        case .add, .subtract: 1
        case .multiply, .divide: 2
        case .power: 3
        case .ee: 4
        }
    }

    var isRightAssociative: Bool { self == .power }
}

enum AngleUnit: String, CaseIterable, Codable {
    case deg, rad
}

/// 숫자 표시 방식 (설정에서 바뀜)
struct NumberStyle: Equatable {
    var grouping = true
    /// nil = 자동
    var fractionDigits: Int? = nil
}

struct Operand {
    var value: Decimal
    /// 계산식 줄에 보일 글자 (예: "sin(30°)", "√16")
    var label: String
}

enum Token {
    case operand(Operand)
    case op(BinaryOp)
    case open
    case close
}

struct CalcError: Error {
    let message: String
    static let divideByZero = CalcError(message: "0으로 나눌 수 없어요")
    static let tooBig = CalcError(message: "숫자가 너무 커요")
    static let invalid = CalcError(message: "계산할 수 없어요")
}

// MARK: - 계산기

@Observable
final class Calculator {
    /// 위쪽 작은 줄
    private(set) var expression = ""
    private(set) var errorMessage: String?
    private(set) var memory: Decimal?
    var angleUnit: AngleUnit = .deg
    /// 공학 모드 2nd 키
    var isSecond = false
    var style = NumberStyle()
    /// "=" 로 계산이 끝날 때마다 (계산식, 결과) 전달 → 기록 저장
    @ObservationIgnored var onEvaluate: ((String, Decimal) -> Void)?

    private var tokens: [Token] = []
    /// 사용자가 치고 있는 숫자 원문
    private var typing: String?
    /// 함수 결과·상수·기록 불러오기처럼 '친 게 아닌' 숫자
    private var entry: Operand?
    /// 아무것도 입력 중이 아닐 때 큰 글씨로 보일 값
    private var shown: Decimal = 0
    private var justEvaluated = false
    private var repeatOp: (BinaryOp, Operand)?

    static let maxDigits = 15

    var displayText: String {
        if let errorMessage { return errorMessage }
        if let typing { return Self.formatTyping(typing, grouping: style.grouping) }
        return format(entry?.value ?? shown)
    }

    /// 지금 화면에 보이는 숫자 값
    var currentValue: Decimal {
        if let typing { return Decimal(string: typing) ?? 0 }
        return entry?.value ?? shown
    }

    // MARK: 버튼

    func press(_ label: String) {
        if label != "AC", errorMessage != nil {
            // 오류 상태에서는 숫자·괄호·상수로 새로 시작, 나머지는 무시
            guard ["0","1","2","3","4","5","6","7","8","9",".","(","π","e","mr"].contains(label) else { return }
            clear()
        }
        switch label {
        case _ where label.count == 1 && label.first!.isASCII && label.first!.isNumber: digit(label)
        case ".": decimalPoint()
        case "AC": clear()
        case "±": negate()
        case "%": percent()
        case "=": equals()
        case "(": openParen()
        case ")": closeParen()
        case "+": binary(.add)
        case "−": binary(.subtract)
        case "×": binary(.multiply)
        case "÷": binary(.divide)
        case "xʸ": binary(.power)
        case "EE": binary(.ee)
        case "2nd": isSecond.toggle()
        case "deg", "rad": angleUnit = angleUnit == .deg ? .rad : .deg
        case "π": constant(Operand(value: Self.pi, label: "π"))
        case "e": constant(Operand(value: Self.euler, label: "e"))
        case "mc": memory = nil
        case "m+": memoryAdd(1)
        case "m−": memoryAdd(-1)
        case "mr": if let memory { constant(Operand(value: memory, label: format(memory))) }
        default: unary(label)
        }
    }

    /// 기록에서 고른 숫자를 불러오기
    func recall(_ value: Decimal) {
        if errorMessage != nil { clear() }
        constant(Operand(value: value, label: format(value)))
    }

    func clear() {
        expression = ""
        errorMessage = nil
        tokens = []
        typing = nil
        entry = nil
        shown = 0
        justEvaluated = false
        repeatOp = nil
    }

    // MARK: 숫자 입력

    private func digit(_ d: String) {
        prepareForNewOperand()
        var t = typing ?? ""
        if t.filter(\.isNumber).count >= Self.maxDigits { return }
        switch t {
        case "", "0": t = d
        case "-0": t = "-" + d
        default: t += d
        }
        typing = t
    }

    private func decimalPoint() {
        prepareForNewOperand()
        guard let t = typing else { typing = "0."; return }
        if !t.contains(".") { typing = t + "." }
    }

    /// 새 숫자를 시작하기 전 정리: "=" 직후면 새 계산, 함수 결과는 덮어쓰기, ")" 뒤면 × 자동 삽입
    private func prepareForNewOperand() {
        if justEvaluated {
            justEvaluated = false
            tokens = []
            expression = ""
            repeatOp = nil
        }
        if typing != nil { return }
        entry = nil
        if case .close? = tokens.last { tokens.append(.op(.multiply)) }
        updateExpression()
    }

    private func constant(_ c: Operand) {
        if justEvaluated {
            justEvaluated = false
            tokens = []
            repeatOp = nil
        } else if let cur = commitEntry() {
            // 2π → 2 × π
            tokens += [.operand(cur), .op(.multiply)]
        } else if case .close? = tokens.last {
            tokens.append(.op(.multiply))
        }
        entry = c
        updateExpression()
    }

    private func negate() {
        if var t = typing {
            t = t.hasPrefix("-") ? String(t.dropFirst()) : "-" + t
            typing = t
        } else if var e = entry {
            e.value = -e.value
            e.label = Self.isPlainNumber(e.label) ? format(e.value) : "−(\(e.label))"
            entry = e
        } else if justEvaluated {
            shown = -shown
        } else {
            typing = "-0"
        }
    }

    private func percent() {
        let target = takeOperandForUnary()
        // 아이폰 방식: 200 + 10% → 200 + 20
        var value = target.value / 100
        if tokens.count >= 2, case .op(let op) = tokens[tokens.count - 1], op == .add || op == .subtract,
           case .operand(let base) = tokens[tokens.count - 2] {
            value = base.value * target.value / 100
        }
        entry = Operand(value: value, label: "\(target.label)%")
        updateExpression()
    }

    private func memoryAdd(_ sign: Decimal) {
        let v = currentValue
        memory = (memory ?? 0) + sign * v
        if typing != nil {
            entry = Operand(value: v, label: format(v))
            typing = nil
        }
    }

    // MARK: 연산자·괄호

    private func binary(_ op: BinaryOp) {
        if justEvaluated {
            justEvaluated = false
            repeatOp = nil
            tokens = [.operand(Operand(value: shown, label: format(shown)))]
        } else if let cur = commitEntry() {
            tokens.append(.operand(cur))
        } else if case .op? = tokens.last {
            tokens.removeLast() // 연산자 바꾸기
        } else if tokens.isEmpty {
            tokens.append(.operand(Operand(value: shown, label: format(shown))))
        } else if case .open? = tokens.last {
            tokens.append(.operand(Operand(value: 0, label: "0")))
        }
        tokens.append(.op(op))
        updateExpression()
    }

    private func openParen() {
        if justEvaluated {
            justEvaluated = false
            tokens = []
            repeatOp = nil
        } else if let cur = commitEntry() {
            tokens += [.operand(cur), .op(.multiply)]
        } else if case .close? = tokens.last {
            tokens.append(.op(.multiply))
        }
        tokens.append(.open)
        updateExpression()
    }

    private func closeParen() {
        guard !justEvaluated, openCount > 0 else { return }
        if let cur = commitEntry() {
            tokens.append(.operand(cur))
        } else if case .op? = tokens.last {
            tokens.removeLast()
        } else if case .open? = tokens.last {
            tokens.append(.operand(Operand(value: 0, label: "0")))
        }
        tokens.append(.close)
        if let start = matchingOpenIndex(), let v = try? Self.evaluate(Array(tokens[start...])) {
            shown = v
        }
        updateExpression()
    }

    private var openCount: Int {
        tokens.reduce(0) { n, t in
            switch t {
            case .open: n + 1
            case .close: n - 1
            default: n
            }
        }
    }

    /// 맨 끝 ")" 와 짝인 "(" 위치
    private func matchingOpenIndex() -> Int? {
        var depth = 0
        for i in tokens.indices.reversed() {
            switch tokens[i] {
            case .close: depth += 1
            case .open:
                depth -= 1
                if depth == 0 { return i }
            default: break
            }
        }
        return nil
    }

    // MARK: 함수

    /// 함수가 적용될 숫자 꺼내기: 입력 중인 숫자 → 바로 앞 괄호 묶음 → 화면 숫자
    private func takeOperandForUnary() -> Operand {
        if justEvaluated {
            justEvaluated = false
            repeatOp = nil
            tokens = []
            return Operand(value: shown, label: format(shown))
        }
        if let cur = commitEntry() { return cur }
        if case .close? = tokens.last, let start = matchingOpenIndex() {
            let group = Array(tokens[start...])
            tokens.removeSubrange(start...)
            let value = (try? Self.evaluate(group)) ?? shown
            return Operand(value: value, label: Self.render(group))
        }
        return Operand(value: shown, label: format(shown))
    }

    private func unary(_ name: String) {
        let x = takeOperandForUnary()
        do {
            let result = try apply(name, to: x)
            entry = result
            shown = result.value
            updateExpression()
        } catch let e as CalcError {
            fail(expression: Self.render(tokens), message: e.message)
        } catch {
            fail(expression: Self.render(tokens), message: CalcError.invalid.message)
        }
    }

    private func apply(_ name: String, to x: Operand) throws -> Operand {
        // 접두·접미 기호용 (√16, (2 + 3)²)
        let p = Self.isPlainNumber(x.label) || Self.isWrapped(x.label) ? x.label : "(\(x.label))"
        // 함수 호출용 (ln(5), sin((2 + 3)°))
        let arg = Self.isWrapped(x.label) ? String(x.label.dropFirst().dropLast()) : x.label
        let v = x.value
        let d = Self.toDouble(v)
        let degSign = angleUnit == .deg ? "°" : ""
        let toRad = angleUnit == .deg ? Double.pi / 180 : 1
        let fromRad = angleUnit == .deg ? 180 / Double.pi : 1

        switch name {
        case "x²": return Operand(value: try Self.checked(v * v), label: "\(p)²")
        case "x³": return Operand(value: try Self.checked(v * v * v), label: "\(p)³")
        case "√":
            guard v >= 0 else { throw CalcError.invalid }
            return Operand(value: try Self.fromDouble(d.squareRoot()), label: "√\(p)")
        case "∛": return Operand(value: try Self.fromDouble(cbrt(d)), label: "∛\(p)")
        case "1/x":
            guard v != 0 else { throw CalcError.divideByZero }
            return Operand(value: 1 / v, label: "1/\(p)")
        case "x!":
            guard v >= 0, v <= 100, v == Self.rounded(v, 0) else { throw CalcError.invalid }
            let n = NSDecimalNumber(decimal: v).intValue
            var r: Decimal = 1
            if n > 1 { for i in 2...n { r *= Decimal(i) } }
            return Operand(value: r, label: "\(p)!")
        case "ln":
            guard v > 0 else { throw CalcError.invalid }
            return Operand(value: try Self.fromDouble(log(d)), label: "ln(\(arg))")
        case "log":
            guard v > 0 else { throw CalcError.invalid }
            return Operand(value: try Self.fromDouble(log10(d)), label: "log(\(arg))")
        case "eˣ": return Operand(value: try Self.fromDouble(exp(d)), label: "e^\(p)")
        case "10ˣ":
            let r = v == Self.rounded(v, 0) && abs(v) <= 99
                ? try Self.binary(10, .power, v)
                : try Self.fromDouble(pow(10, d))
            return Operand(value: r, label: "10^\(p)")
        case "sin": return Operand(value: try Self.fromDouble(sin(d * toRad)), label: "sin(\(arg)\(degSign))")
        case "cos": return Operand(value: try Self.fromDouble(cos(d * toRad)), label: "cos(\(arg)\(degSign))")
        case "tan":
            if angleUnit == .deg {
                // 90°, 270° … 은 값이 없음
                let r = (v - 90) / 180
                if r == Self.rounded(r, 0) { throw CalcError.invalid }
            }
            return Operand(value: try Self.fromDouble(tan(d * toRad)), label: "tan(\(arg)\(degSign))")
        case "sin⁻¹":
            guard abs(d) <= 1 else { throw CalcError.invalid }
            return Operand(value: try Self.fromDouble(asin(d) * fromRad), label: "sin⁻¹(\(arg))")
        case "cos⁻¹":
            guard abs(d) <= 1 else { throw CalcError.invalid }
            return Operand(value: try Self.fromDouble(acos(d) * fromRad), label: "cos⁻¹(\(arg))")
        case "tan⁻¹":
            return Operand(value: try Self.fromDouble(atan(d) * fromRad), label: "tan⁻¹(\(arg))")
        default:
            return x
        }
    }

    // MARK: "="

    private func equals() {
        if justEvaluated {
            guard let (op, rhs) = repeatOp else { return }
            tokens = [.operand(Operand(value: shown, label: format(shown))), .op(op), .operand(rhs)]
        } else {
            if let cur = commitEntry() {
                tokens.append(.operand(cur))
            } else if case .op? = tokens.last {
                tokens.removeLast()
            }
            while case .open? = tokens.last { tokens.removeLast() }
            for _ in 0..<max(openCount, 0) { tokens.append(.close) }
        }
        guard !tokens.isEmpty else { return }

        let text = Self.render(tokens)
        do {
            let result = try Self.evaluate(tokens)
            // 숫자 하나만 놓고 "=" 누른 건 기록하지 않음 (sin(30°) 같은 건 기록)
            var shouldRecord = tokens.count > 1
            if tokens.count == 1, case .operand(let only) = tokens[0], !Self.isPlainNumber(only.label) {
                shouldRecord = true
            }
            if tokens.count >= 3, case .operand(let rhs) = tokens[tokens.count - 1],
               case .op(let op) = tokens[tokens.count - 2] {
                repeatOp = (op, rhs)
            } else {
                repeatOp = nil
            }
            expression = text
            shown = result
            tokens = []
            justEvaluated = true
            if shouldRecord { onEvaluate?(text, result) }
        } catch let e as CalcError {
            fail(expression: text, message: e.message)
        } catch {
            fail(expression: text, message: CalcError.invalid.message)
        }
    }

    // MARK: 내부 도우미

    /// 입력 중인 숫자를 확정해서 꺼냄
    private func commitEntry() -> Operand? {
        let result: Operand?
        if let typing {
            let v = Decimal(string: typing) ?? 0
            result = Operand(value: v, label: Self.formatTyping(typing, grouping: style.grouping))
        } else {
            result = entry
        }
        typing = nil
        entry = nil
        if let result { shown = result.value }
        return result
    }

    private func updateExpression() {
        expression = Self.render(tokens)
    }

    private func fail(expression: String, message: String) {
        clear()
        self.expression = expression
        errorMessage = message
    }

    func format(_ d: Decimal) -> String {
        Self.format(d, style: style)
    }

    // MARK: - 계산 (순서 규칙)

    static func evaluate(_ tokens: [Token]) throws -> Decimal {
        var output: [Decimal] = []
        var stack: [Token] = []

        func reduce() throws {
            guard case .op(let op)? = stack.popLast(), output.count >= 2 else { throw CalcError.invalid }
            let b = output.removeLast()
            let a = output.removeLast()
            output.append(try binary(a, op, b))
        }

        for token in tokens {
            switch token {
            case .operand(let o):
                output.append(o.value)
            case .op(let op):
                while case .op(let top)? = stack.last,
                      top.precedence > op.precedence || (top.precedence == op.precedence && !op.isRightAssociative) {
                    try reduce()
                }
                stack.append(token)
            case .open:
                stack.append(token)
            case .close:
                while case .op? = stack.last { try reduce() }
                if case .open? = stack.last { stack.removeLast() }
            }
        }
        while let top = stack.last {
            if case .op = top { try reduce() } else { stack.removeLast() }
        }
        guard output.count == 1 else { throw CalcError.invalid }
        return output[0]
    }

    static func binary(_ a: Decimal, _ op: BinaryOp, _ b: Decimal) throws -> Decimal {
        switch op {
        case .add: return try checked(a + b)
        case .subtract: return try checked(a - b)
        case .multiply: return try checked(a * b)
        case .divide:
            guard b != 0 else { throw CalcError.divideByZero }
            return try checked(a / b)
        case .power:
            if b == rounded(b, 0), abs(b) <= 999 {
                let n = NSDecimalNumber(decimal: b).intValue
                if n >= 0 { return try checked(pow(a, n)) }
                guard a != 0 else { throw CalcError.divideByZero }
                return try checked(1 / pow(a, -n))
            }
            guard a >= 0 else { throw CalcError.invalid }
            return try fromDouble(Foundation.pow(toDouble(a), toDouble(b)))
        case .ee:
            guard b == rounded(b, 0), abs(b) <= 99 else { throw CalcError.invalid }
            let n = NSDecimalNumber(decimal: b).intValue
            let scale = pow(Decimal(10), abs(n))
            return try checked(n >= 0 ? a * scale : a / scale)
        }
    }

    private static let limit = Decimal(sign: .plus, exponent: 100, significand: 1)

    static func checked(_ d: Decimal) throws -> Decimal {
        if d.isNaN { throw CalcError.tooBig }
        if abs(d) >= limit { throw CalcError.tooBig }
        return d
    }

    static func toDouble(_ d: Decimal) -> Double {
        NSDecimalNumber(decimal: d).doubleValue
    }

    /// Double 결과를 Decimal로: 소수 12자리 반올림으로 0.49999999999999994 → 0.5
    static func fromDouble(_ v: Double) throws -> Decimal {
        guard v.isFinite else { throw CalcError.invalid }
        guard abs(v) < 1e100 else { throw CalcError.tooBig }
        return rounded(Decimal(v), 12)
    }

    static func rounded(_ d: Decimal, _ scale: Int) -> Decimal {
        var input = d
        var out = Decimal()
        NSDecimalRound(&out, &input, scale, .plain)
        return out
    }

    static let pi = Decimal(string: "3.14159265358979323846264338327950288")!
    static let euler = Decimal(string: "2.71828182845904523536028747135266250")!

    // MARK: - 글자 만들기

    static func render(_ tokens: [Token]) -> String {
        var s = ""
        for t in tokens {
            switch t {
            case .operand(let o): s += o.label
            case .op(let op):
                switch op {
                case .power, .ee: s += op.rawValue
                default: s += " \(op.rawValue) "
                }
            case .open: s += "("
            case .close: s += ")"
            }
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// "(…)" 로 바깥이 한 번 감싸져 있는지
    static func isWrapped(_ s: String) -> Bool {
        guard s.hasPrefix("("), s.hasSuffix(")") else { return false }
        var depth = 0
        for (i, ch) in s.enumerated() {
            if ch == "(" { depth += 1 }
            if ch == ")" { depth -= 1 }
            if depth == 0 && i < s.count - 1 { return false }
        }
        return true
    }

    static func isPlainNumber(_ s: String) -> Bool {
        if s == "π" || s == "e" { return true }
        return !s.isEmpty && s.allSatisfy { $0.isNumber || $0 == "," || $0 == "." }
    }

    private static func makeFormatter(_ style: NumberStyle, scientific: Bool) -> NumberFormatter {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        if scientific {
            f.numberStyle = .scientific
            f.maximumSignificantDigits = 10
            f.exponentSymbol = "e"
        } else {
            f.numberStyle = .decimal
            f.usesGroupingSeparator = style.grouping
            f.maximumFractionDigits = style.fractionDigits ?? 10
            f.minimumFractionDigits = style.fractionDigits ?? 0
        }
        return f
    }

    /// 결과 표시: 소수 10자리(또는 설정한 자리)에서 반올림, 너무 크거나 작으면 지수 표기
    static func format(_ d: Decimal, style: NumberStyle = NumberStyle()) -> String {
        let r = rounded(d, style.fractionDigits ?? 10)
        let magnitude = abs(r)
        let useScientific = magnitude >= Decimal(sign: .plus, exponent: 15, significand: 1)
            || (style.fractionDigits == nil && magnitude != 0
                && magnitude < Decimal(sign: .plus, exponent: -9, significand: 1))
        let f = makeFormatter(style, scientific: useScientific)
        let source = useScientific ? d : r
        let text = f.string(from: source as NSDecimalNumber) ?? "\(source)"
        return text == "-0" ? "0" : text
    }

    /// 입력 중인 숫자 표시: 천 단위 쉼표만 넣고 끝의 "." / "0"은 그대로
    static func formatTyping(_ t: String, grouping: Bool = true) -> String {
        var s = Substring(t)
        let negative = s.hasPrefix("-")
        if negative { s = s.dropFirst() }
        let parts = s.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intPart = String(parts[0])
        var grouped = ""
        for (i, ch) in intPart.reversed().enumerated() {
            if grouping && i > 0 && i % 3 == 0 { grouped.append(",") }
            grouped.append(ch)
        }
        var out = (negative ? "-" : "") + String(grouped.reversed())
        if parts.count > 1 { out += "." + parts[1] }
        return out
    }
}
