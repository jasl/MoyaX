import Foundation

public enum StubBehavior {
    case Immediate
    case Delayed(NSTimeInterval)
}

public enum StubResponse {
    /// The network returned a response, including status code and data.
    case NetworkResponse(Int, NSData)

    /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
    case NetworkError(NSError)
}

public struct StubRule {
    let URL: NSURL
    let behavior: StubBehavior
    let response: StubResponse

    public init(URL: NSURL, behavior: StubBehavior, response: StubResponse) {
        self.URL = URL
        self.behavior = behavior
        self.response = response
    }
}

public struct StubAction: Equatable, Hashable {
    let URL: NSURL
    let method: Method

    public init(URL: NSURL, method: Method) {
        self.URL = URL
        self.method = method
    }

    public var hashValue: Int {
        return "\(self.method.rawValue) \(String(self.URL))".hashValue
    }
}

public func ==(lhs: StubAction, rhs: StubAction) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

internal final class StubCancellableToken: Cancellable {
    private(set) var isCancelled = false

    func cancel() {
        self.isCancelled = true
    }
}

public class StubBackend: BackendType {
    private var stubs: [StubAction: StubRule]

    public init() {
        self.stubs = [:]
    }

    public func stubTarget(target: TargetType, response: StubResponse, behavior: StubBehavior = .Immediate) {
        let action = StubAction(URL: target.fullURL, method: target.method)
        let rule = StubRule(URL: target.fullURL, behavior: behavior, response: response)

        self.stubs[action] = rule
    }

    public func removeAllStubs() {
        self.stubs = [:]
    }

    public func removeStubTarget(target: TargetType) {
        let action = StubAction(URL: target.fullURL, method: target.method)

        self.stubs.removeValueForKey(action)
    }

    public func request(request: NSURLRequest, completion: (response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> ()) -> Cancellable {
        let action = StubAction(URL: request.URL!, method: Method(rawValue: request.HTTPMethod!)!)
        guard let stubRule = self.stubs[action] else {
            fatalError("Request not stubbed yet.")
        }

        let cancellableToken = StubCancellableToken()

        switch stubRule.behavior {
        case .Immediate:
            self.stubResponse(stubRule, cancellableToken: cancellableToken, completion: completion)
        case .Delayed(let delay):
            let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
            let killTime = dispatch_time(DISPATCH_TIME_NOW, killTimeOffset)
            dispatch_after(killTime, dispatch_get_main_queue()) {
                self.stubResponse(stubRule, cancellableToken: cancellableToken, completion: completion)
            }
        }

        return cancellableToken
    }

    func stubResponse(rule: StubRule, cancellableToken: StubCancellableToken, completion: (response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> ()) {
        if cancellableToken.isCancelled {
            completion(response: nil, data: nil, error: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
            return
        }

        switch rule.response {
        case .NetworkResponse(let statusCode, let data):
            let response = NSHTTPURLResponse(URL: rule.URL, statusCode: statusCode, HTTPVersion: nil, headerFields: nil)
            completion(response: response, data: data, error: nil)
        case .NetworkError(let error):
            completion(response: nil, data: nil, error: error)
        }
    }
}

public class GenericStubBackend<Target: TargetType>: StubBackend {
    public func stub(target: Target, response: StubResponse, behavior: StubBehavior = .Immediate) {
        self.stubTarget(target, response: response, behavior: behavior)
    }

    public func removeStub(target: Target) {
        self.removeStubTarget(target)
    }
}
