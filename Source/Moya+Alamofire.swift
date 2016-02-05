import Foundation
import Alamofire

public typealias Manager = Alamofire.Manager

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
