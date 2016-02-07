import Foundation
import RxSwift

/// Subclass of MoyaXProvider that returns Observable instances when requests are made. Much better than using completion closures.
public class RxMoyaXProvider<Target: TargetType>: MoyaXGenericProvider<Target> {
    /// Initializes a reactive provider.
    override public init(backend: BackendType = AlamofireBackend(),
                         plugins: [PluginType] = [],
                         willTransformToRequest: WillTransformToRequestClosure? = nil) {
        super.init(backend: backend, plugins: plugins, willTransformToRequest: willTransformToRequest)
    }

    /// Designated request-making method.
    public func request(token: Target) -> Observable<Response> {

        // Creates an observable that starts a request each time it's subscribed to.
        return Observable.create { [weak self] observer in
            let cancellableToken = self?.request(token) { result in
                switch result {
                case let .Success(response):
                    observer.onNext(response)
                    observer.onCompleted()
                case let .Failure(error):
                    observer.onError(error)
                }
            }

            return AnonymousDisposable {
                cancellableToken?.cancel()
            }
        }
    }
}
