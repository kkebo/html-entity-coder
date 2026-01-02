import Testing

@testable import HTMLEntityCoder

@Test
func encodeAllNamedEntities() async {
    await withDiscardingTaskGroup { group in
        for (key, value) in reversedNamedChars {
            group.addTask {
                #expect(encodeHTML(String(key)) == "&" + value)
            }
        }
    }
}

@Test
func otherNonASCIISymbolsAreRepresentedThroughHexadecimalEscapes() {
    #expect(encodeHTML("foo\u{A9}bar\u{1D306}baz\u{2603}qux") == "foo&copy;bar&#x1D306;baz&#x2603;qux")
}

@Test
func encodeToNamedHTMLEntities() {
    #expect(encodeHTML("\u{E4}\u{F6}\u{FC}\u{C4}\u{D6}\u{DC}") == "&auml;&ouml;&uuml;&Auml;&Ouml;&Uuml;")
}
