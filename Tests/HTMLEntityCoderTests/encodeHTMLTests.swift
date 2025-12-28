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
