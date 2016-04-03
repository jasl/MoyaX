import Foundation

public typealias Completion = Result<Response, Error> -> ()

public enum HTTPMethod: String {
    case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}

public enum HTTPRequestBodyEncoding {
    case Form
    case FormWithMultipartData
    case JSON
}

// http://www.iana.org/assignments/media-types/media-types.xhtml
public enum MultipartData {
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
    var bodyEncoding: HTTPRequestBodyEncoding { get }

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
    var bodyEncoding: HTTPRequestBodyEncoding {
        return .Form
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

public protocol Cancellable {
    func cancel()
}

internal final class CancellableTokenForAborting: Cancellable {
    func cancel() {}
}
