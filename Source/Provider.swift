import Foundation
import Result

/// Closure to be executed when a request has completed.
public typealias Completion = (result: Result<Response, Error>) -> ()


/// Request provider class. Requests should be made through this class only.
public class MoyaXProvider {
    public let backend: BackendType

    /// A list of plugins
    /// e.g. for logging, network activity indicator or credentials
    public let plugins: [PluginType]

    /// Initializes a provider.
    public init(backend: BackendType = AlamofireBackend(),
                plugins: [PluginType] = []) {
        self.backend = backend
        self.plugins = plugins
    }

    /// Designated request-making method. Returns a Cancellable token to cancel the request later.
    public func request(target: TargetType, completion: Completion) -> Cancellable {
        let endpoint = target.endpoint
        let request = endpoint.mutableURLRequest

        self.plugins.forEach { $0.willSendRequest(request, target: target) }

        return self.backend.request(request) { (response: NSHTTPURLResponse?, data: NSData?, error: NSError?) in
            let result = convertResponseToResult(response, data: data, error: error)

            // Inform all plugins about the response
            self.plugins.forEach { $0.didReceiveResponse(result, target: target) }

            completion(result: result)
        }
    }
}

public class MoyaXGenericProvider<Target: TargetType>: MoyaXProvider {
    public override init(backend: BackendType = AlamofireBackend(),
                         plugins: [PluginType] = []) {
        super.init(backend: backend, plugins: plugins)
    }

    public func request(target: Target, completion: Completion) -> Cancellable {
        return super.request(target, completion: completion)
    }
}

internal func convertResponseToResult(response: NSHTTPURLResponse?, data: NSData?, error: NSError?) ->
        Result<Response, Error> {
    switch (response, data, error) {
    case let (.Some(response), .Some(data), .None):
        let response = Response(statusCode: response.statusCode, data: data, response: response)
        return .Success(response)
    case let (_, _, .Some(error)):
        let error = Error.Underlying(error)
        return .Failure(error)
    default:
        let error = Error.Underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil))
        return .Failure(error)
    }
}
