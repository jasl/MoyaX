import Foundation

public final class Endpoint {
    public let target: TargetType?
    public var perform = true

    public let URL: NSURL
    public let method: Method

    public var parameterEncoding: ParameterEncoding
    public var parameters: [String: AnyObject]
    public var headerFields: [String: String]

    public init(target: TargetType) {
        self.target = target

        self.URL = target.fullURL
        self.method = target.method

        self.parameters = target.parameters
        self.parameterEncoding = target.parameterEncoding
        self.headerFields = target.headerFields
    }

    public var mutableURLRequest: NSMutableURLRequest {
        let mutableURLRequest = NSMutableURLRequest(URL: self.URL)
        mutableURLRequest.HTTPMethod = self.method.rawValue
        mutableURLRequest.allHTTPHeaderFields = self.headerFields

        return mutableURLRequest
    }

    public var encodedMutableURLRequest: NSMutableURLRequest {
        return self.parameterEncoding.encodeMutableRequest(self.mutableURLRequest, parameters: self.parameters).0
    }
}
