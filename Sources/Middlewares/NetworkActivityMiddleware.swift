import Foundation

/// Network activity change notification type.
public enum NetworkActivityChangeType {
    case Began, Ended
}

/// Notify a request's network activity changes (request begins or ends).
public final class NetworkActivityMiddleware: Middleware {

    public typealias NetworkActivityClosure = (NetworkActivityChangeType) -> ()
    let networkActivityClosure: NetworkActivityClosure

    public init(networkActivityClosure: NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }

    // MARK: Middleware

    /// Called by the provider as soon as the request is about to start
    public func willSendRequest(target: Target, endpoint: Endpoint) {
        networkActivityClosure(.Began)
    }

    /// Called by the provider as soon as a response arrives, even the request is cancelled.
    public func didReceiveResponse(target: Target, response: Result<Response, Error>) {
        networkActivityClosure(.Ended)
    }
}
