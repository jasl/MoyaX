import Foundation

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
        return Endpoint(URL: self.fullURL, method: self.method, parameters: self.parameters, parameterEncoding: self.parameterEncoding, headerFields: self.headerFields)
    }
}

public protocol BackendType: class {
    func request(request: NSURLRequest, target: TargetType, completion: ((response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> ())) -> Cancellable
}

/// Protocol to define the opaque type returned from a request
public protocol Cancellable {
    func cancel()
}
