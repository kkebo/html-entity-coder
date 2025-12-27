import DequeModule

/// Decodes any HTML named and numerical character references.
public func decodeHTML(_ input: String) -> String {
    var output: ContiguousArray<Unicode.Scalar> = []
    output.reserveCapacity(input.unicodeScalars.count)
    var input = Deque(input.unicodeScalars)
    while let c = input.popFirst() {
        switch c {
        case "&":
            var tokenizer = CharRefTokenizer(inAttr: false)
            repeat {
                switch tokenizer.step(input: &input) {
                case .continue: continue
                case .doneChars(let c1, let c2): output.append(contentsOf: [c1, c2])
                case .doneChar(let c): output.append(c)
                }
                break
            } while true
        case let c: output.append(c)
        }
    }
    return String(output.map(Character.init))
}
