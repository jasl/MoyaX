import Foundation

/// Endpoint is the intermediate representation for a target on requesting
public final class Endpoint {
    /// The raw target instance
    public let target: Target?

    public let URL: NSURL
    public let method: HTTPMethod

    public var headerFields: [String:String]

    public var parameters: [String:AnyObject]
    public let parameterEncoding: ParameterEncoding

    public init(target: Target) {
        self.target = target

        self.URL = target.fullURL
        self.method = target.method
        self.parameterEncoding = target.parameterEncoding

        self.parameters = target.parameters
        self.headerFields = target.headerFields
    }
}
