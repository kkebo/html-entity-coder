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
