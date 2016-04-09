import Foundation
import MoyaX

struct TestTarget: Target {
    var baseURL: NSURL { return NSURL(string: "http://test.local")! }
    var path: String { return "foo/bar" }

    var method: HTTPMethod { return .GET }
    var parameters: [String: AnyObject] { return ["Nemesis": "Harvey"] }
    var headerFields: [String: String] { return ["Title": "Dominar"] }
}
