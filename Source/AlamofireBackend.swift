import Foundation
import Alamofire

public protocol AlamofireRequestType {

    // Note:
    //
    // We use this protocol instead of the Alamofire request to avoid leaking that abstraction.

    /// Retrieve an NSURLRequest represetation.
    var request: NSURLRequest? { get }

    /// Authenticates the request with a username and password.
    func authenticate(user user: String, password: String, persistence: NSURLCredentialPersistence) -> Self

    /// Authnenticates the request with a NSURLCredential instance.
    func authenticate(usingCredential credential: NSURLCredential) -> Self
}

extension Request: AlamofireRequestType {}

/// Internal token that can be used to cancel requests
internal final class CancellableToken: Cancellable , CustomDebugStringConvertible {
    let cancelAction: () -> Void
    let request : Request?
    private(set) var canceled: Bool = false

    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    func cancel() {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }
        guard !canceled else { return }
        canceled = true
        cancelAction()
    }

    init(action: () -> Void){
        self.cancelAction = action
        self.request = nil
    }

    init(request : Request){
        self.request = request
        self.cancelAction = {
            request.cancel()
        }
    }

    var debugDescription: String {
        guard let request = self.request else {
            return "Empty Request"
        }
        return request.debugDescription
    }
}

public func DefaultAlamofireManager() -> Manager {
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders

    let manager = Manager(configuration: configuration)
    manager.startRequestsImmediately = false
    return manager
}

public class AlamofireBackend: BackendType {
    let manager: Manager
    let willSendRequest: (AlamofireRequestType -> Request)?

    public init(manager: Manager = DefaultAlamofireManager(), willSendRequest: (AlamofireRequestType -> Request)? = nil) {
        self.manager = manager
        self.willSendRequest = willSendRequest
    }

    public func request(request: NSURLRequest, completion: (response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> ()) -> Cancellable {
        var alamoRequest = self.manager.request(request)

        if let willSendRequest = self.willSendRequest {
            alamoRequest = willSendRequest(alamoRequest)
        }

        // Perform the actual request
        alamoRequest.response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
            completion(response: response, data: data, error: error)
        }

        alamoRequest.resume()

        return CancellableToken(request: alamoRequest)
    }
}
