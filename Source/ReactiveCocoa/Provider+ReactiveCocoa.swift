import Foundation
import ReactiveCocoa

/// Subclass of MoyaXProvider that returns SignalProducer instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaXProvider<Target: TargetType>: MoyaXGenericProvider<Target> {

    /// Initializes a reactive provider.
    public override init(backend: BackendType = AlamofireBackend(),
                         plugins: [PluginType] = [],
                         willTransformToRequest: WillTransformToRequestClosure? = nil) {
        super.init(backend: backend, plugins: plugins, willTransformToRequest: willTransformToRequest)
    }

    /// Designated request-making method.
    public func request(token: Target, withCustomBackend backend: BackendType? = nil) -> SignalProducer<Response, Error> {
        // Creates a producer that starts a request each time it's started.
        return SignalProducer { [weak self] observer, requestDisposable in
            let cancellableToken = self?.request(token, withCustomBackend: backend) { result in
                switch result {
                case let .Success(response):
                    observer.sendNext(response)
                    observer.sendCompleted()
                case let .Failure(error):
                    observer.sendFailed(error)
                }
            }

            requestDisposable.addDisposable {
                // Cancel the request
                cancellableToken?.cancel()
            }
        }
    }

    @available(*, deprecated, message="This will be removed when ReactiveCocoa 4 becomes final. Please visit https://github.com/Moya/Moya/issues/298 for more information.")
    public func request(token: Target, withCustomBackend backend: BackendType? = nil) -> RACSignal {
        return request(token, withCustomBackend: backend).toRACSignal()
    }
}