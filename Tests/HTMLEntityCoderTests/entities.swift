import Foundation

struct Entry: Decodable {
    var codepoints: [UInt32]
}

// swift-format-ignore: NeverUseForceTry, NeverForceUnwrap
let entities = try! JSONDecoder()
    .decode(
        [String: Entry].self,
        from: Data(contentsOf: Bundle.module.url(forResource: "entities", withExtension: "json")!)
    )
