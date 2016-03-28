import Foundation
import Alamofire

internal final class CancellableToken: Cancellable, CustomDebugStringConvertible {
    let request: Alamofire.Request
    private(set) var isCancelled: Bool = false

    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    init(request: Request) {
        self.request = request
    }

    func cancel() {
        OSSpinLockLock(&self.lock)
        defer { OSSpinLockUnlock(&self.lock) }
        if self.isCancelled { return }

        self.isCancelled = true
        request.cancel()
    }

    var debugDescription: String {
        return request.debugDescription
    }
}

public class AlamofireBackend: BackendType {
    public static let defaultManager: Manager = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 4

        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false

        return manager
    }()

    let manager: Alamofire.Manager
    let willPerformRequest: ((Endpoint, Alamofire.Request) -> ())?
    let didReceiveResponse: ((Endpoint, Alamofire.Response<NSData, NSError>) -> ())?

    public init(manager: Manager = defaultManager,
                willPerformRequest: ((Endpoint, Alamofire.Request) -> ())? = nil,
                didReceiveResponse: ((Endpoint, Alamofire.Response<NSData, NSError>) -> ())? = nil) {
        self.manager = manager
        self.willPerformRequest = willPerformRequest
        self.didReceiveResponse = didReceiveResponse
    }

    public func request(endpoint: Endpoint, completion: Completion) -> Cancellable {
        let alamofireRequest = self.manager.request(endpoint.encodedMutableURLRequest)

        self.willPerformRequest?(endpoint, alamofireRequest)

        alamofireRequest.responseData { alamofireResponse in
            self.didReceiveResponse?(endpoint, alamofireResponse)

            guard let rawResponse = alamofireResponse.response else {
                if case let .Failure(error) = alamofireResponse.result {
                    if error.code == -999 {
                        completion(.Incomplete(Error.Cancelled))
                    } else {
                        completion(.Incomplete(Error.BackendUnexpect(error)))
                    }
                } else {
                    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
                    completion(.Incomplete(Error.BackendUnexpect(error)))
                }

                return
            }

            switch alamofireResponse.result {
            case let .Success(data):
                let response = Response(statusCode: rawResponse.statusCode, data: data, response: rawResponse)
                completion(.Response(response))
            case let .Failure(error):
                completion(.Incomplete(Error.BackendResponse(error)))
            }
        }

        if !self.manager.startRequestsImmediately {
            alamofireRequest.resume()
        }

        return CancellableToken(request: alamofireRequest)
    }
}
