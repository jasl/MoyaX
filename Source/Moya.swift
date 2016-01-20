import Foundation

/// Represents an HTTP method.
public enum Method: String {
    case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT
}

public enum StubBehavior {
    case Never
    case Immediate
    case Delayed(seconds: NSTimeInterval)
}

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Method { get }
    var parameters: [String: AnyObject]? { get }
    var sampleData: NSData { get }
}

/// Protocol to define the opaque type returned from a request
public protocol Cancellable {
    func cancel()
}

/// Mark: Defaults

// These functions are default mappings to MoyaProvider's properties: endpoints, requests, manager, etc.

public func DefaultEndpointMapping<Target: TargetType>(target: Target) -> Endpoint {
    let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
    return Endpoint(URL: url, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
}

public func DefaultRequestMapping(endpoint: Endpoint, closure: NSURLRequest -> Void) {
    return closure(endpoint.urlRequest)
}

public func DefaultAlamofireManager() -> Manager {
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders

    let manager = Manager(configuration: configuration)
    manager.startRequestsImmediately = false
    return manager
}

/// Mark: Stubbing

public func NeverStub<Target: TargetType>(_: Target) -> StubBehavior {
    return .Never
}

public func ImmediatelyStub<Target: TargetType>(_: Target) -> StubBehavior {
    return .Immediate
}

public func DelayedStub<Target: TargetType>(seconds: NSTimeInterval)(_: Target) -> StubBehavior {
    return .Delayed(seconds: seconds)
}
