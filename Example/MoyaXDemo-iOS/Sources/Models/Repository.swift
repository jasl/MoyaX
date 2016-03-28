import Foundation

struct Repository: DictionaryMappable {
    let name: String

    init?(byDictionary dict: [String: AnyObject]) {
        if let name = dict["name"] as? String {
            self.name = name
        } else {
            return nil
        }
    }
}
