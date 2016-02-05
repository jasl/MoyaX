import Foundation
import Result

/// Closure to be executed when a request has completed.
public typealias Completion = (result: Result<Response, Error>) -> ()

/// Request provider class. Requests should be made through this class only.
public class MoyaXProvider<Target: TargetType> {

    /// Closure that defines the endpoints for the provider.
    public typealias EndpointClosure = Target -> Endpoint

    /// Closure that resolves an Endpoint into an NSURLRequest.
    public typealias RequestClosure = (Endpoint, NSURLRequest -> Void) -> Void

    public let endpointClosure: EndpointClosure
    public let requestClosure: RequestClosure
    public let manager: Manager

    /// A list of plugins
    /// e.g. for logging, network activity indicator or credentials
    public let plugins: [PluginType]

    /// Initializes a provider.
    public init(endpointClosure: EndpointClosure = DefaultEndpointMapping,
                requestClosure: RequestClosure = DefaultRequestMapping,
                manager: Manager = DefaultAlamofireManager(),
                plugins: [PluginType] = []) {

        self.endpointClosure = endpointClosure
        self.requestClosure = requestClosure
        self.manager = manager
        self.plugins = plugins
    }

    /// Designated request-making method. Returns a Cancellable token to cancel the request later.
    public func request(target: Target, completion: Completion) -> Cancellable {
        let endpoint = self.endpointClosure(target)
        var cancellableToken = CancellableWrapper()

        let performNetworking = { (request: NSURLRequest) in
            if cancellableToken.isCancelled { return }

            cancellableToken.innerCancellable = self.sendRequest(target, request: request, completion: completion)
        }

        requestClosure(endpoint, performNetworking)

        return cancellableToken
    }

    func sendRequest(target: Target, request: NSURLRequest, completion: Completion) -> CancellableToken {
        let alamoRequest = manager.request(request)
        let plugins = self.plugins

        // Give plugins the chance to alter the outgoing request
        plugins.forEach { $0.willSendRequest(alamoRequest, target: target) }

        // Perform the actual request
        alamoRequest.response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
            let result = convertResponseToResult(response, data: data, error: error)
            // Inform all plugins about the response
            plugins.forEach { $0.didReceiveResponse(result, target: target) }
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
