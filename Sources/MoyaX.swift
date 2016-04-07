import Foundation

public typealias Completion = Result<Response, Error> -> ()

public enum HTTPMethod: String {
    case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}

public enum ParameterEncoding {
    case URL
    case MultipartFormData
    case JSON
}

// http://www.iana.org/assignments/media-types/media-types.xhtml
public enum MultipartFormData {
    case Data(NSData, fileName: String, mimeType: String)
    case File(NSURL, fileName: String, mimeType: String)
    case Stream(NSInputStream, length: UInt64, fileName: String, mimeType: String)
}

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: HTTPMethod { get }

    var headerFields: [String: String] { get }

    var parameters: [String: AnyObject] { get }
    var parameterEncoding: ParameterEncoding { get }

    var fullURL: NSURL { get }

    var endpoint: Endpoint { get }
}

public extension TargetType {
    var method: HTTPMethod {
        return .GET
    }

    var headerFields: [String: String] {
        return [:]
    }

    var parameters: [String: AnyObject] {
        return [:]
    }
    var parameterEncoding: ParameterEncoding {
        return .URL
    }

    var fullURL: NSURL {
        return self.baseURL.URLByAppendingPathComponent(self.path)
    }

    var endpoint: Endpoint {
        return Endpoint(target: self)
    }
}

public protocol MiddlewareType {
    func willSendRequest(target: TargetType, endpoint: Endpoint)

    func didReceiveResponse(target: TargetType, response: Result<Response, Error>)
}


public protocol BackendType: class {
    func request(endpoint: Endpoint, completion: Completion) -> Cancellable
}

public protocol Cancellable: CustomDebugStringConvertible {
    func cancel()
    var debugDescription: String { get }
}

internal final class AbortingCancellableToken: Cancellable {
    func cancel() {}

    var debugDescription: String {
        return "Stub CancellableToken for a aborting task."
    }
}
