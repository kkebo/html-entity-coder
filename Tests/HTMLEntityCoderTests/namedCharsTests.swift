import Testing

@testable import HTMLEntityCoder

@Test
func testNamedChars() async throws {
    try await withThrowingDiscardingTaskGroup { group in
        for (key, value) in entities {
            group.addTask {
                let key = key.dropFirst()
                let result1 = try #require(namedChars[key])
                let result2 = try #require(processedNamedChars[key])
                #expect(result1 == result2)
                switch result1 {
                case (let c1, "\0"): #expect(value.codepoints == [c1.value])
                case (let c1, let c2): #expect(value.codepoints == [c1.value, c2.value])
                }
            }
        }
    }
}

@Test
func testReversedNamedChars() async throws {
    try await withThrowingDiscardingTaskGroup { group in
        for value in entities.values {
            group.addTask {
                let str = try String(String.UnicodeScalarView(value.codepoints.lazy.map { try #require(.init($0)) }))
                switch str {
                case "\u{66}\u{6A}": break
                case "\u{205F}\u{200A}": break
                case let str:
                    #expect(str.count == 1)
                    let c = Character(str)
                    let key = try #require(reversedNamedChars[c])
                    switch try #require(namedChars[key]) {
                    case (let c1, "\0"): #expect(value.codepoints == [c1.value])
                    case (let c1, let c2): #expect(value.codepoints == [c1.value, c2.value])
                    }
                }
            }
        }
    }
}
