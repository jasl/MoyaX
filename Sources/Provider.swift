import Foundation

/// Request provider class. Requests should be made through this class only.
public class MoyaXProvider {

    public let backend: Backend
    public let middlewares: [Middleware]
    public let prepareForEndpoint: (Endpoint -> ())?

    /**
       Initializes a provider.

       - Parameter backend: The backend used to perform request.
       - Parameter middlewares: Middlewares will be called on `request` method.
       - Parameter prepareForEndpoint: a closure will be called on `request` method, mostly used for modifying endpoint,
                                       e.g: add an authentication header
    */
    public init(backend: Backend = AlamofireBackend(),
                middlewares: [Middleware] = [],
                prepareForEndpoint: (Endpoint -> ())? = nil) {
        self.backend = backend
        self.middlewares = middlewares
        self.prepareForEndpoint = prepareForEndpoint
    }

    /**
       Dupplicate the provider.

       - Parameter backend: Using new backend instead of existing configuration.
       - Parameter middlewares: Using new middlewares instead of existing configuration.
       - Parameter prepareForEndpoint: Using new `prepareForEndpoint` hook instead of existing configuration.
    */
    public func copy(backend: Backend? = nil,
                     middlewares: [Middleware]? = nil,
                     prepareForEndpoint: (Endpoint -> ())? = nil) -> MoyaXProvider {
        return MoyaXProvider(backend: backend ?? self.backend,
                middlewares: middlewares ?? self.middlewares,
                prepareForEndpoint: prepareForEndpoint ?? self.prepareForEndpoint)
    }

    /**
        Creates a request for given target and call the completion once the request has finished.

        The flow is equivalent to:

            let endpoint = target.endpoint
            prepareForEndpoint?(endpoint)
            middlewares.each { $0.willSendRequest(target, endpoint) }
            if endpoint.willPerform {
                response = backend.request(endpoint)
            } else {
                response = .Incomplete(Error.Aborted)
            }
            middlewares.each { $0.didReceiveResponse(target, response) }
            completion(response)

        - Parameter target:            The target.
        - Parameter withCustomBackend: Optional, the backend used to perform request.
        - Parameter completion:        The handler to be called once the request has finished.

        - Returns: The cancellable token for the request.
    */
    public final func request(target: Target, withCustomBackend backend: Backend? = nil, completion: Completion) -> CancellableToken {
        let endpoint = target.endpoint

        self.prepareForEndpoint?(endpoint)

        self.middlewares.forEach {
            $0.willSendRequest(target, endpoint: endpoint)
        }

        let backend = backend ?? self.backend

        return backend.request(endpoint) {
            response in
            self.middlewares.forEach {
                $0.didReceiveResponse(target, response: response)
            }

            completion(response)
        }
    }
}

/// Request provider class. Requests should be made through this class only.
/// This is the generic provider that convenient for `enum` targets
public class MoyaXGenericProvider<TargetType:Target>: MoyaXProvider {

    /**
       Initializes a provider.

       - Parameter backend: The backend used to perform request.
       - Parameter middlewares: Middlewares will be called on `request` method.
       - Parameter prepareForEndpoint: a closure will be called on `request` method, mostly used for modifying endpoint,
                                       e.g: add an authentication header
    */
    public override init(backend: Backend = AlamofireBackend(),
                         middlewares: [Middleware] = [],
                         prepareForEndpoint: (Endpoint -> ())? = nil) {
        super.init(backend: backend, middlewares: middlewares, prepareForEndpoint: prepareForEndpoint)
    }

    /**
       Dupplicate the provider.

       - Parameter backend: Using new backend instead of existing configuration.
       - Parameter middlewares: Using new middlewares instead of existing configuration.
       - Parameter prepareForEndpoint: Using new `prepareForEndpoint` hook instead of existing configuration.
    */
    public override func copy(backend: Backend? = nil,
                              middlewares: [Middleware]? = nil,
                              prepareForEndpoint: (Endpoint -> ())? = nil) -> MoyaXGenericProvider<TargetType> {
        return MoyaXGenericProvider<TargetType>(backend: backend ?? self.backend,
                middlewares: middlewares ?? self.middlewares,
                prepareForEndpoint: prepareForEndpoint ?? self.prepareForEndpoint)
    }

    /**
        Creates a request for given target and call the completion once the request has finished.

        The flow is equivalent to:

            let endpoint = target.endpoint
            prepareForEndpoint?(endpoint)
            middlewares.each { $0.willSendRequest(target, endpoint) }
            if endpoint.willPerform {
                response = backend.request(endpoint)
            } else {
                response = .Incomplete(Error.Aborted)
            }
            middlewares.each { $0.didReceiveResponse(target, response) }
            completion(response)

        - Parameter target:            The target.
        - Parameter withCustomBackend: Optional, the backend used to perform request.
        - Parameter completion:        The handler to be called once the request has finished.

        - Returns: The cancellable token for the request.
    */
    public func request(target: TargetType, withCustomBackend backend: Backend? = nil, completion: Completion) -> CancellableToken {
        return super.request(target, withCustomBackend: backend, completion: completion)
    }
}
