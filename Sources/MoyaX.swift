import Foundation

public typealias Completion = Result<Response, Error> -> ()

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: NSURL { get }
    var path: String { get }

    var method: Method { get }
    var parameters: [String: AnyObject] { get }
    var parameterEncoding: ParameterEncoding { get }
    var headerFields: [String: String] { get }

    var fullURL: NSURL { get }
    var endpoint: Endpoint { get }
}

public extension TargetType {
    // Default values
    var method: Method {
        return .GET
    }

    var parameters: [String: AnyObject] {
        return [:]
    }
    var parameterEncoding: ParameterEncoding {
        return .URL
    }
    var headerFields: [String: String] {
        return [:]
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
