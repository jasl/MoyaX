import Foundation

protocol DictionaryMappable {
    init?(byDictionary dict: [String: AnyObject])
}

extension Array where Element: DictionaryMappable {
    init(byArray array: [[String: AnyObject]]) {
        self.init()

        if array.isEmpty { return }

        for item in array {
            if let object = Element.init(byDictionary: item) {
                self.append(object)
            }
        }
    }
}
