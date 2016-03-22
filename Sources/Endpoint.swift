import Foundation

/// Struct for reifying a target of the Target enum unto a concrete Endpoint.
public struct Endpoint {
    public let URL: NSURL
    public let method: Method

    public var parameterEncoding: ParameterEncoding
    public var parameters: [String: AnyObject]
    public var headerFields: [String: String]

    /// Main initializer for Endpoint.
    public init(URL: NSURL,
                method: Method = Method.GET,
                parameters: [String: AnyObject] = [:],
                parameterEncoding: ParameterEncoding = .URL,
                headerFields: [String: String] = [:]) {

        self.URL = URL
        self.method = method
        self.parameters = parameters
        self.parameterEncoding = parameterEncoding
        self.headerFields = headerFields
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
