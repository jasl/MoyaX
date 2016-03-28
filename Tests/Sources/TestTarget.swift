import Foundation
import MoyaX

struct TestTarget: TargetType {
    var baseURL: NSURL { return NSURL(string: "http://test.local")! }
    var path: String { return "foo/bar" }

    var method: MoyaX.Method { return .GET }
    var parameters: [String: AnyObject] { return ["Nemesis": "Harvey"] }
    var parameterEncoding: ParameterEncoding { return .URL }
    var headerFields: [String: String] { return ["Title": "Dominar"] }
}
