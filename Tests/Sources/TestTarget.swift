import Foundation
import MoyaX

struct SimpliestTarget: Target {
    let baseURL = NSURL(string: "https://httpbin.org")!
    let path: String

    init(path: String = "get") {
        self.path = path
    }
}

struct WildcardTarget: Target {
    let baseURL = NSURL(string: "https://httpbin.org")!
    var path: String
    var method: HTTPMethod
    var headerFields: [String: String]
    var parameters: [String: AnyObject]
    var parameterEncoding: ParameterEncoding

    init(path: String, method: HTTPMethod = .GET, headerFields: [String: String] = [:],
         parameters: [String: AnyObject] = [:], parameterEncoding: ParameterEncoding = .URL) {
        self.path = path
        self.method = method
        self.headerFields = headerFields
        self.parameters = parameters
        self.parameterEncoding = parameterEncoding
    }
}
