import Foundation
import Result

/// Closure to be executed when a request has completed.
public typealias Completion = (result: Result<Response, Error>) -> ()

/// Request provider class. Requests should be made through this class only.
public class MoyaXProvider<Target: TargetType> {
    public let manager: Manager

    /// A list of plugins
    /// e.g. for logging, network activity indicator or credentials
    public let plugins: [PluginType]

    /// Initializes a provider.
    public init(manager: Manager = DefaultAlamofireManager(),
                plugins: [PluginType] = []) {
        self.manager = manager
        self.plugins = plugins
    }

    /// Designated request-making method. Returns a Cancellable token to cancel the request later.
    public func request(target: Target, completion: Completion) -> Cancellable {
        let endpoint = target.toEndpoint()
        let request = endpoint.toMutableURLRequest().0

        self.plugins.forEach { $0.willSendRequest(request, target: target) }

        return self.sendRequest(target, request: request, completion: completion)
    }

    func sendRequest(target: Target, request: NSURLRequest, completion: Completion) -> CancellableToken {
        let alamoRequest = manager.request(request)

        // Perform the actual request
        alamoRequest.response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
            let result = convertResponseToResult(response, data: data, error: error)
            // Inform all plugins about the response
            self.plugins.forEach { $0.didReceiveResponse(result, target: target) }
            completion(result: result)
        }

        alamoRequest.resume()

        return CancellableToken(request: alamoRequest)
    }
}

private struct CancellableWrapper: Cancellable {
    var innerCancellable: CancellableToken? = nil

    private var isCancelled = false

    func cancel() {
        innerCancellable?.cancel()
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
