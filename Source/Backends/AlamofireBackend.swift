import Foundation
import Alamofire

/// Internal token that can be used to cancel requests
internal final class CancellableToken: Cancellable, CustomDebugStringConvertible {
    let cancelAction: () -> Void
    let request : Request?
    private(set) var isCancelled: Bool = false

    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    func cancel() {
        OSSpinLockLock(&self.lock)
        defer { OSSpinLockUnlock(&self.lock) }
        if self.isCancelled { return }

        self.isCancelled = true
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
        if self.request == nil {
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
    let willSendRequest: ((Request, TargetType) -> Request)?

    public init(manager: Manager = DefaultAlamofireManager(), willSendRequest: ((Request, TargetType) -> Request)? = nil) {
        self.manager = manager
        self.willSendRequest = willSendRequest
    }

    public func request(request: NSURLRequest, target: TargetType, completion: (response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> ()) -> Cancellable {
        var alamoRequest = self.manager.request(request)

        if let willSendRequest = self.willSendRequest {
            alamoRequest = willSendRequest(alamoRequest, target)
        }

        // Perform the actual request
        alamoRequest.response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
            completion(response: response, data: data, error: error)
        }

        alamoRequest.resume()

        return CancellableToken(request: alamoRequest)
    }
}
