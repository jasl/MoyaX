import Foundation

public enum Error: ErrorType {
    case ImageMapping(Response)
    case JSONMapping(Response)
    case StringMapping(Response)
    case StatusCode(Response)
    case Data(Response)
    case Underlying(ErrorType)
}

public extension Error {
    /// Depending on error type, returns a Response object.
    var response: Response? {
        switch self {
        case .ImageMapping(let response): return response
        case .JSONMapping(let response): return response
        case .StringMapping(let response): return response
        case .StatusCode(let response): return response
        case .Data(let response): return response
        case .Underlying: return nil
        }
    }
}

@available(*, deprecated, message="This will be removed when ReactiveCocoa 4 becomes final. Please visit https://github.com/Moya/Moya/issues/298 for more information.")
public let MoyaXErrorDomain = "MoyaX"

@available(*, deprecated, message="This will be removed when ReactiveCocoa 4 becomes final. Please visit https://github.com/Moya/Moya/issues/298 for more information.")
public enum MoyaXErrorCode: Int {
    case ImageMapping = 0
    case JSONMapping
    case StringMapping
    case StatusCode
    case Data
}

@available(*, deprecated, message="This will be removed when ReactiveCocoa 4 becomes final. Please visit https://github.com/Moya/Moya/issues/298 for more information.")
public extension Error {

    // Used to convert MoyaXError to NSError for RACSignal
    var nsError: NSError {
        switch self {
        case .ImageMapping(let response):
            return NSError(domain: MoyaXErrorDomain, code: MoyaXErrorCode.ImageMapping.rawValue, userInfo: ["data" : response])
        case .JSONMapping(let response):
            return NSError(domain: MoyaXErrorDomain, code: MoyaXErrorCode.JSONMapping.rawValue, userInfo: ["data" : response])
        case .StringMapping(let response):
            return NSError(domain: MoyaXErrorDomain, code: MoyaXErrorCode.StringMapping.rawValue, userInfo: ["data" : response])
        case .StatusCode(let response):
            return NSError(domain: MoyaXErrorDomain, code: MoyaXErrorCode.StatusCode.rawValue, userInfo: ["data" : response])
        case .Data(let response):
            return NSError(domain: MoyaXErrorDomain, code: MoyaXErrorCode.Data.rawValue, userInfo: ["data" : response])
        case .Underlying(let error):
            return error as NSError
        }
    }
}
