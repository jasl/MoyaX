import Foundation

public final class Endpoint {
    public let target: TargetType?
    public var perform = true

    public let URL: NSURL
    public let method: HTTPMethod

    public var headerFields: [String: String]

    public var parameters: [String: AnyObject]
    public let parameterEncoding: ParameterEncoding

    public init(target: TargetType) {
        self.target = target

        self.URL = target.fullURL
        self.method = target.method
        self.parameterEncoding = target.parameterEncoding

        self.parameters = target.parameters
        self.headerFields = target.headerFields
    }
}
