import Foundation

/// Used to store all response data returned from a completed request.
public struct Response: CustomDebugStringConvertible {
    public let response: NSURLResponse?

    public let statusCode: Int
    public let data: NSData

    public lazy var responseClass: ResponseStatus = {
        return ResponseStatus(statusCode: self.statusCode)
    }()

    public init(statusCode: Int, data: NSData, response: NSURLResponse? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.response = response
    }

    public var description: String {
        return "Status Code: \(statusCode), Data Length: \(data.length)"
    }

    public var debugDescription: String {
        return description
    }
}

/**
   The category for response status code

   - informational: status code in 100 to 199
   - success: status code in 200 to 299
   - redirection: status code in 300 to 399
   - clientError: status code in 400 to 499
   - serverError: status code in 500 to 599
   - undefined: other status code
*/
public enum ResponseStatus {
    case informational
    case success
    case redirection
    case clientError
    case serverError
    case undefined

    public init(statusCode: Int) {
        switch statusCode {
        case 100 ..< 200:
            self = .informational
        case 200 ..< 300:
            self = .success
        case 300 ..< 400:
            self = .redirection
        case 400 ..< 500:
            self = .clientError
        case 500 ..< 600:
            self = .serverError
        default:
            self = .undefined
        }
    }
}
