import Testing

@testable import HTMLEntityCoder

@Test
func decodeAllNamedEntities() async throws {
    try await withThrowingDiscardingTaskGroup { group in
        for (key, value) in entities {
            group.addTask {
                let value = try String(String.UnicodeScalarView(value.codepoints.lazy.map { try #require(.init($0)) }))
                #expect(decodeHTML(key) == value)
            }
        }
    }
}

@Test
func onlyDecodeOnce1() {
    #expect(decodeHTML("&amp;amp;amp;") == "&amp;amp;")
}

@Test
func onlyDecodeOnce2() {
    #expect(decodeHTML("&#x26;amp;") == "&amp;")
}

@Test
func ambiguousAmpersand1() {
    #expect(decodeHTML("a&foololthisdoesntexist;b") == "a&foololthisdoesntexist;b")
}

@Test
func ambiguousAmpersand2() {
    #expect(decodeHTML("foo &lolwat; bar") == "foo &lolwat; bar")
}

@Test
func legacyNamedReferencesWithoutATrailingSemicolon() {
    #expect(decodeHTML("&notin; &noti &notin &copy123") == "\u{2209} \u{AC}i \u{AC}in \u{A9}123")
}

@Test
func legacyNamedReferences() {
    #expect(
        decodeHTML("&amp;xxx; &amp;xxx &ampthorn; &ampthorn &ampcurren;t &ampcurrent")
            == "&xxx; &xxx &thorn; &thorn &curren;t &current"
    )
}

@Test
func hexadecimalEscape() {
    #expect(decodeHTML("a&#x1D306;b&#X0000000000001d306;c") == "a\u{1D306}b\u{1D306}c")
}

@Test
func decimalEscape() {
    #expect(decodeHTML("a&#119558;b&#169;c&#00000000000000000169;d") == "a\u{1D306}b\u{A9}c\u{A9}d")
}

@Test
func specialNumericalEscapes() {
    #expect(
        decodeHTML("a&#xD834;&#xDF06;b&#55348;&#57094;c a&#x0;b&#0;c")
            == "a\u{FFFD}\u{FFFD}b\u{FFFD}\u{FFFD}c a\u{FFFD}b\u{FFFD}c"
    )
}

@Test
func outOfRangeHexadecimalEscape1() {
    #expect(decodeHTML("a&#x9999999999999999;b") == "a\u{FFFD}b")
}

@Test
func outOfRangeHexadecimalEscape2() {
    #expect(decodeHTML("a&#x110000;b") == "a\u{FFFD}b")
}

@Test
func ambiguousAmpersandInTextContent() {
    #expect(decodeHTML("foo&ampbar") == "foo&bar")
}

@Test
func hexadecimalEscapeWithoutTrailingSemicolon() {
    #expect(decodeHTML("foo&#x1D306qux") == "foo\u{1D306}qux")
}

@Test
func decimalEscapeWithoutTrailingSemicolon() {
    #expect(decodeHTML("foo&#119558qux") == "foo\u{1D306}qux")
}

@Test
func attributeValueContext1() {
    #expect(decodeHTML("foo&ampbar", inAttr: true) == "foo&ampbar")
}

@Test
func attributeValueContext2() {
    #expect(decodeHTML("foo&amp;bar", inAttr: true) == "foo&bar")
}

@Test
func attributeValueContext3() {
    #expect(decodeHTML("foo&amp;", inAttr: true) == "foo&")
}

@Test
func attributeValueContext4() {
    #expect(decodeHTML("foo&amp=", inAttr: true) == "foo&amp=")
}

@Test
func attributeValueContext5() {
    #expect(decodeHTML("foo&amp", inAttr: true) == "foo&")
}

@Test
func attributeValueContext6() {
    #expect(decodeHTML("foo&amplol", inAttr: true) == "foo&amplol")
}

@Test
func `"I'm &notit; I tell you" as attribute value`() {
    #expect(decodeHTML("I\'m &notit; I tell you", inAttr: true) == "I\'m &notit; I tell you")
}

@Test
func `"I'm &notin; I tell you" as attribute value`() {
    #expect(decodeHTML("I\'m &notin; I tell you", inAttr: true) == "I\'m \u{2209} I tell you")
}

@Test
func `decoding "&#x8D;"`() {
    #expect(decodeHTML("&#x8D;") == "\u{8D}")
}

@Test
func `decoding "&#xD;"`() {
    #expect(decodeHTML("&#xD;") == "\u{0D}")
}

@Test
func `decoding "&#x94;"`() {
    #expect(decodeHTML("&#x94;") == "\u{201D}")
}

@Test
func `decoding "&#x1;"`() {
    #expect(decodeHTML("&#x1;") == "\u{01}")
}

@Test
func `decoding "&#x10FFFF;"`() {
    #expect(decodeHTML("&#x10FFFF;") == "\u{10FFFF}")
}

@Test
func `decoding "&#196605;" (valid code point)`() {
    #expect(decodeHTML("&#196605;") == "\u{2FFFD}")
}

@Test
func `decoding "&#xZ"`() {
    #expect(decodeHTML("&#xZ") == "&#xZ")
}

@Test
func `decoding "&#Z"`() {
    #expect(decodeHTML("&#Z") == "&#Z")
}

@Test
func `decoding "&#00" numeric character reference`() {
    #expect(decodeHTML("&#00") == "\u{FFFD}")
}

@Test
func decodingZeroPrefixedNumericCharacterReference() {
    #expect(decodeHTML("&#0128;") == "\u{20AC}")
}
