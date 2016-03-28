import Foundation

/// Request provider class. Requests should be made through this class only.
public class MoyaXProvider {

    public let backend: BackendType
    public let middlewares: [MiddlewareType]
    private let prepareForEndpoint: (Endpoint -> ())?

    /// Initializes a provider.
    public init(backend: BackendType = AlamofireBackend(),
                middlewares: [MiddlewareType] = [],
                prepareForEndpoint: (Endpoint -> ())? = nil) {
        self.backend = backend
        self.middlewares = middlewares
        self.prepareForEndpoint = prepareForEndpoint
    }

    /// Designated request-making method. Returns a Cancellable token to cancel the request later.
    public final func request(target: TargetType, withCustomBackend backend: BackendType? = nil, completion: Completion) -> Cancellable {
        let endpoint = target.endpoint

        self.prepareForEndpoint?(endpoint)

        self.middlewares.forEach { $0.willSendRequest(target, endpoint: endpoint) }

        guard endpoint.perform else {
            let error: Result<Response, Error> = .Incomplete(.Abort)
            self.middlewares.forEach { $0.didReceiveResponse(target, response: error) }

            return CancellableTokenForAborting()
        }

        let backend = backend ?? self.backend

        return backend.request(endpoint) { response in
            self.middlewares.forEach { $0.didReceiveResponse(target, response: response) }

            completion(response)
        }
    }
}

public class MoyaXGenericProvider<Target: TargetType>: MoyaXProvider {
    public override init(backend: BackendType = AlamofireBackend(),
                         middlewares: [MiddlewareType] = [],
                         prepareForEndpoint: (Endpoint -> ())? = nil) {
        super.init(backend: backend, middlewares: middlewares, prepareForEndpoint: prepareForEndpoint)
    }

    public func request(target: Target, withCustomBackend backend: BackendType? = nil, completion: Completion) -> Cancellable {
        return super.request(target, withCustomBackend: backend, completion: completion)
    }
}
