import DequeModule

private enum CharRefState {
    case initial
    case named
    case namedEnd(endIndex: Substring.Index, replaceChars: (Unicode.Scalar, Unicode.Scalar))
    case ambiguousAmpersand
    case numeric
    case hexadecimalStart(uppercase: Bool)
    case decimalStart
    case hexadecimal
    case decimal
    case numericEnd
}

enum CharRefProcessResult: ~Copyable {
    case `continue`
    case doneChars(Unicode.Scalar, Unicode.Scalar)
    case doneChar(Unicode.Scalar)
}

struct CharRefTokenizer: ~Copyable {
    private var state: CharRefState = .initial
    private var num: Int = 0
    private var numTooBig: Bool = false
    private var nameBuffer: Substring = ""
    private var lastMatch: (endIndex: Substring.Index, replaceChars: (Unicode.Scalar, Unicode.Scalar))?
    private let isInAttr: Bool

    init(inAttr isInAttr: Bool) {
        self.isInAttr = isInAttr
    }

    mutating func step(input: inout Deque<Unicode.Scalar>) -> CharRefProcessResult {
        switch self.state {
        case .initial: self.initial(input: &input)
        case .named: self.named(input: &input)
        case .namedEnd(let endIndex, let replaceChars):
            self.namedEnd(endIndex: endIndex, replaceChars: replaceChars, input: &input)
        case .ambiguousAmpersand: self.ambiguousAmpersand(input: &input)
        case .numeric: self.numeric(input: &input)
        case .hexadecimalStart(let uppercase): self.hexadecimalStart(uppercase: uppercase, input: &input)
        case .decimalStart: self.decimalStart(input: &input)
        case .hexadecimal: self.hexadecimal(input: &input)
        case .decimal: self.decimal(input: &input)
        case .numericEnd: self.numericEnd(input: &input)
        }
    }

    @inline(__always)
    private mutating func initial(input: inout Deque<Unicode.Scalar>) -> CharRefProcessResult {
        switch input.first {
        case ("0"..."9")?, ("A"..."Z")?, ("a"..."z")?:
            self.state = .named
            return .continue
        case "#":
            input.removeFirst()
            self.state = .numeric
            return .continue
        case _: return .doneChar("&")
        }
    }

    @inline(__always)
    private mutating func named(input: inout Deque<Unicode.Scalar>) -> CharRefProcessResult {
        repeat {
            guard let c = input.first else {
                guard let (endIndex, chars) = self.lastMatch else {
                    input.prepend(contentsOf: self.nameBuffer.unicodeScalars)
                    return .doneChar("&")
                }
                self.state = .namedEnd(endIndex: endIndex, replaceChars: chars)
                return .continue
            }
            input.removeFirst()
            self.nameBuffer.append(Character(c))
            switch processedNamedChars[self.nameBuffer] {
            case ("\0", _)?: break
            case let chars?: self.lastMatch = (self.nameBuffer.endIndex, chars)
            case nil:
                if let (endIndex, chars) = self.lastMatch {
                    self.state = .namedEnd(endIndex: endIndex, replaceChars: chars)
                } else {
                    self.state = .ambiguousAmpersand
                }
                return .continue
            }
        } while true
    }

    @inline(__always)
    private mutating func namedEnd(
        endIndex: Substring.Index,
        replaceChars: (Unicode.Scalar, Unicode.Scalar),
        input: inout Deque<Unicode.Scalar>
    ) -> CharRefProcessResult {
        let lastChar = self.nameBuffer[..<endIndex].last
        let nextChar: Character? =
            if self.nameBuffer.endIndex != endIndex {
                self.nameBuffer[endIndex]
            } else {
                nil
            }
        switch (isInAttr, lastChar, nextChar) {
        case (_, ";", _): break
        case (true, _, "="?), (true, _, ("0"..."9")?), (true, _, ("A"..."Z")?), (true, _, ("a"..."z")?):
            input.prepend(contentsOf: self.nameBuffer.unicodeScalars)
            return .doneChar("&")
        case _:
            // tokenizer.emitError(.missingSemicolon)
            break
        }
        input.prepend(contentsOf: self.nameBuffer[endIndex...].unicodeScalars)
        return switch replaceChars {
        case (let c1, "\0"): .doneChar(c1)
        case (let c1, let c2): .doneChars(c1, c2)
        }
    }

    @inline(__always)
    private mutating func ambiguousAmpersand(input: inout Deque<Unicode.Scalar>) -> CharRefProcessResult {
        repeat {
            guard let c = input.first else {
                input.prepend(contentsOf: self.nameBuffer.unicodeScalars)
                return .doneChar("&")
            }
            switch c {
            case "0"..."9", "A"..."Z", "a"..."z":
                input.removeFirst()
                self.nameBuffer.append(Character(c))
                continue
            case ";":
                // tokenizer.emitError(.unknownNamedCharRef)
                break
            case _: break
            }
            input.prepend(contentsOf: self.nameBuffer.unicodeScalars)
            return .doneChar("&")
        } while true
    }

    @inline(__always)
    private mutating func numeric(input: inout Deque<Unicode.Scalar>) -> CharRefProcessResult {
        switch input.first {
        case "X":
            input.removeFirst()
            self.state = .hexadecimalStart(uppercase: true)
        case "x":
            input.removeFirst()
            self.state = .hexadecimalStart(uppercase: false)
        case _: self.state = .decimalStart
        }
        return .continue
    }

    @inline(__always)
    private mutating func hexadecimalStart(
        uppercase: Bool,
        input: inout Deque<Unicode.Scalar>
    ) -> CharRefProcessResult {
        switch input.first {
        case ("0"..."9")?, ("A"..."F")?, ("a"..."f")?:
            self.state = .hexadecimal
            return .continue
        case _:
            // tokenizer.emitError(.absenceDigits)
            input.prepend(uppercase ? "X" : "x")
            input.prepend("#")
            return .doneChar("&")
        }
    }

    @inline(__always)
    private mutating func decimalStart(input: inout Deque<Unicode.Scalar>) -> CharRefProcessResult {
        switch input.first {
        case ("0"..."9")?:
            self.state = .decimal
            return .continue
        case _:
            // tokenizer.emitError(.absenceDigits)
            input.prepend("#")
            return .doneChar("&")
        }
    }

    @inline(__always)
    private mutating func hexadecimal(input: inout Deque<Unicode.Scalar>) -> CharRefProcessResult {
        repeat {
            if let c = input.first {
                switch c {
                case "0"..."9":
                    input.removeFirst()
                    self.num &*= 16
                    if self.num > 0x10FFFF {
                        self.numTooBig = true
                    }
                    self.num &+= Int(c.value &- 0x30)
                    continue
                case "A"..."F":
                    input.removeFirst()
                    self.num &*= 16
                    if self.num > 0x10FFFF {
                        self.numTooBig = true
                    }
                    self.num &+= Int(c.value &- 0x37)
                    continue
                case "a"..."f":
                    input.removeFirst()
                    self.num &*= 16
                    if self.num > 0x10FFFF {
                        self.numTooBig = true
                    }
                    self.num &+= Int(c.value &- 0x57)
                    continue
                case ";":
                    input.removeFirst()
                    self.state = .numericEnd
                    return .continue
                case _: break
                }
            }
            // tokenizer.emitError(.missingSemicolon)
            self.state = .numericEnd
            return .continue
        } while true
    }

    @inline(__always)
    private mutating func decimal(input: inout Deque<Unicode.Scalar>) -> CharRefProcessResult {
        repeat {
            if let c = input.first {
                switch c {
                case "0"..."9":
                    input.removeFirst()
                    self.num &*= 10
                    if self.num > 0x10FFFF {
                        self.numTooBig = true
                    }
                    self.num &+= Int(c.value &- 0x30)
                    continue
                case ";":
                    input.removeFirst()
                    self.state = .numericEnd
                    return .continue
                case _: break
                }
            }
            // tokenizer.emitError(.missingSemicolon)
            self.state = .numericEnd
            return .continue
        } while true
    }

    // swift-format-ignore: NeverForceUnwrap
    @inline(__always)
    private mutating func numericEnd(input: inout Deque<Unicode.Scalar>) -> CharRefProcessResult {
        switch self.num {
        case 0x00:
            // tokenizer.emitError(.nullCharRef)
            return .doneChar("\u{FFFD}")
        case let n where n > 0x10FFFF || self.numTooBig:
            // tokenizer.emitError(.charRefOutOfRange)
            return .doneChar("\u{FFFD}")
        case 0xD800...0xDBFF, 0xDC00...0xDFFF:
            // tokenizer.emitError(.surrogateCharRef)
            return .doneChar("\u{FFFD}")
        case 0xFDD0...0xFDEF, 0xFFFE, 0xFFFF, 0x1FFFE, 0x1FFFF, 0x2FFFE, 0x2FFFF,
            0x3FFFE, 0x3FFFF, 0x4FFFE, 0x4FFFF, 0x5FFFE, 0x5FFFF, 0x6FFFE, 0x6FFFF,
            0x7FFFE, 0x7FFFF, 0x8FFFE, 0x8FFFF, 0x9FFFE, 0x9FFFF, 0xAFFFE, 0xAFFFF,
            0xBFFFE, 0xBFFFF, 0xCFFFE, 0xCFFFF, 0xDFFFE, 0xDFFFF, 0xEFFFE, 0xEFFFF,
            0xFFFFE, 0xFFFFF, 0x10FFFE, 0x10FFFF:
            // tokenizer.emitError(.noncharacterCharRef)
            return .doneChar(Unicode.Scalar(self.num)!)
        case 0x0D, 0x01...0x08, 0x0B, 0x0D...0x1F, 0x7F:
            // tokenizer.emitError(.controlCharRef)
            return .doneChar(Unicode.Scalar(self.num)!)
        case 0x80...0x9F:
            // tokenizer.emitError(.controlCharRef)
            return switch replacements[self.num &- 0x80] {
            case "\0": .doneChar(Unicode.Scalar(self.num)!)
            case let c: .doneChar(c)
            }
        case let n: return .doneChar(Unicode.Scalar(n)!)
        }
    }
}
