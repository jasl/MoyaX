import Foundation

/// Used to store all response data returned from a completed request.
public class Response: CustomDebugStringConvertible {
    public let response: NSURLResponse?

    public let statusCode: Int
    public let data: NSData

    public lazy var responseClass: ResponseClass = {
        return ResponseClass(statusCode: self.statusCode)
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

   - Informational: status code in 100 to 199
   - Success: status code in 200 to 299
   - Redirection: status code in 300 to 399
   - ClientError: status code in 400 to 499
   - ServerError: status code in 500 to 599
   - Undefined: other status code
*/
public enum ResponseClass {
    case Informational
    case Success
    case Redirection
    case ClientError
    case ServerError
    case Undefined

    public init(statusCode: Int) {
        switch statusCode {
        case 100 ..< 200:
            self = .Informational
        case 200 ..< 300:
            self = .Success
        case 300 ..< 400:
            self = .Redirection
        case 400 ..< 500:
            self = .ClientError
        case 500 ..< 600:
            self = .ServerError
        default:
            self = .Undefined
        }
    }
}
