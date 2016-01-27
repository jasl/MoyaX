import Foundation
import RxSwift

/// Subclass of MoyaXProvider that returns Observable instances when requests are made. Much better than using completion closures.
public class RxMoyaXProvider<Target where Target: TargetType>: MoyaXProvider<Target> {
    /// Initializes a reactive provider.
    override public init(endpointClosure: EndpointClosure = MoyaXProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaXProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaXProvider.NeverStub,
        manager: Manager = RxMoyaXProvider<Target>.DefaultAlamofireManager(),
        plugins: [PluginType] = []) {
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
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
                    break
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
