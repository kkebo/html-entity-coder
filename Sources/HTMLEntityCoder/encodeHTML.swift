/// Replaces any characters that aren't printable ASCII characters and `&`, `<`, `>`, `"`, and `'` with HTML character references.
///
/// - Parameter input: The input text.
///
/// - Returns: The encoded text.
public func encodeHTML(_ input: String) -> String {
    var output = ""
    output.reserveCapacity(input.utf8.count)
    for c in input {
        switch reversedNamedChars[c] {
        case let name?: output.append("&" + name)
        case nil:
            switch c {
            case "\u{20}"..."\u{7E}": output.append(c)
            case _:
                output += c.unicodeScalars.lazy
                    .map { "&#x" + String($0.value, radix: 16, uppercase: true) + ";" }
                    .joined()
            }
        }
    }
    return output
}
