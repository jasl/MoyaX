import Foundation

public protocol TargetWithSample: Target {
    var sampleResponse: StubResponse { get }
}

internal final class StubCancellableToken: CancellableToken {
    private(set) var isCancelled = false

    private var lock: dispatch_semaphore_t = dispatch_semaphore_create(1)

    func cancel() {
        dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER)
        defer {
            dispatch_semaphore_signal(lock)
        }
        if self.isCancelled {
            return
        }

        self.isCancelled = true
    }

    var debugDescription: String {
        return "CancellableToken for a stub request."
    }
}

public enum StubBehavior {
    case immediate
    case delayed(NSTimeInterval)
}

public enum StubResponse {
    /// The network returned a response, including status code and data.
    case networkResponse(Int, NSData)

    /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
    case networkError(ErrorType)

    /// You usually don't need this, It's will raise a fetalError
    case noStubError
}

public struct StubRule {
    public typealias ConditionalResponseClosure = (endpoint: Endpoint, target: Target?) -> StubResponse
    let URL: NSURL
    let behavior: StubBehavior?
    let conditionalResponse: ConditionalResponseClosure

    public init(URL: NSURL, behavior: StubBehavior? = nil, response: StubResponse) {
        self.URL = URL
        self.behavior = behavior
        self.conditionalResponse = {
            (_, _) in
            return response
        }
    }

    public init(URL: NSURL, behavior: StubBehavior? = nil, conditionalResponse: ConditionalResponseClosure) {
        self.URL = URL
        self.behavior = behavior
        self.conditionalResponse = conditionalResponse
    }
}

public struct StubAction: Equatable, Hashable {
    let URL: NSURL
    let method: HTTPMethod

    public init(URL: NSURL, method: HTTPMethod) {
        self.URL = URL
        self.method = method
    }

    public var hashValue: Int {
        return "\(self.method.rawValue) \(String(self.URL))".hashValue
    }
}

public func == (lhs: StubAction, rhs: StubAction) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

public class StubBackend: Backend {
    internal var stubs: [StubAction:StubRule]

    public let defaultBehavior: StubBehavior
    public let defaultResponse: StubResponse

    public init(defaultBehavior: StubBehavior = .immediate, defaultResponse: StubResponse = .noStubError) {
        self.stubs = [:]

        self.defaultBehavior = defaultBehavior
        self.defaultResponse = defaultResponse
    }

    public func stubTarget(target: Target, rule: StubRule) {
        let action = StubAction(URL: target.fullURL, method: target.method)
        let rule = rule

        self.stubs[action] = rule
    }

    public func stubTarget(target: Target, behavior: StubBehavior? = nil, conditionalResponse: StubRule.ConditionalResponseClosure) {
        let rule = StubRule(URL: target.fullURL, behavior: behavior, conditionalResponse: conditionalResponse)

        self.stubTarget(target, rule: rule)
    }

    public func stubTarget(target: Target, behavior: StubBehavior? = nil, response: StubResponse) {
        let rule = StubRule(URL: target.fullURL, behavior: behavior, response: response)

        self.stubTarget(target, rule: rule)
    }

    public func removeAllStubs() {
        self.stubs = [:]
    }

    public func removeStubTarget(target: Target) {
        let action = StubAction(URL: target.fullURL, method: target.method)

        self.stubs.removeValueForKey(action)
    }

    public func request(endpoint: Endpoint, completion: Completion) -> CancellableToken {
        let target = endpoint.target
        let action = StubAction(URL: endpoint.URL, method: endpoint.method)

        var response = (target as? TargetWithSample)?.sampleResponse ?? self.defaultResponse
        var behavior = self.defaultBehavior

        if let stubRule = self.stubs[action] {
            response = stubRule.conditionalResponse(endpoint: endpoint, target: target)
            behavior = stubRule.behavior ?? behavior
        }

        let cancellableToken = StubCancellableToken()

        switch behavior {
        case .immediate:
            self.stubResponse(action.URL, response: response, cancellableToken: cancellableToken, completion: completion)
        case .delayed(let delay):
            let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
            let killTime = dispatch_time(DISPATCH_TIME_NOW, killTimeOffset)

            dispatch_after(killTime, dispatch_get_main_queue()) {
                self.stubResponse(action.URL, response: response, cancellableToken: cancellableToken, completion: completion)
            }
        }

        return cancellableToken
    }

    func stubResponse(URL: NSURL, response: StubResponse, cancellableToken: StubCancellableToken, completion: Completion) {
        if cancellableToken.isCancelled {
            completion(.incomplete(Error.backendResponse(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))))
            return
        }

        switch response {
        case .networkResponse(let statusCode, let data):
            let fakeNSHTTPResponse = NSHTTPURLResponse(URL: URL, statusCode: statusCode, HTTPVersion: nil, headerFields: nil)
            let response = Response(statusCode: statusCode, data: data, response: fakeNSHTTPResponse)
            completion(.response(response))
        case .networkError(let error):
            completion(.incomplete(Error.backendResponse(error)))
        case .noStubError:
            fatalError("\(String(URL)) is not stubbed yet.")
        }
    }
}

public class GenericStubBackend<TargetType:Target>: StubBackend {
    public override init(defaultBehavior: StubBehavior = .immediate, defaultResponse: StubResponse = .noStubError) {
        super.init(defaultBehavior: defaultBehavior, defaultResponse: defaultResponse)
    }

    public func stub(target: TargetType, behavior: StubBehavior? = nil, response: StubResponse) {
        self.stubTarget(target, behavior: behavior, response: response)
    }

    public func stub(target: TargetType, behavior: StubBehavior? = nil, conditionalResponse: StubRule.ConditionalResponseClosure) {
        self.stubTarget(target, behavior: behavior, conditionalResponse: conditionalResponse)
    }

    public func removeStub(target: TargetType) {
        self.removeStubTarget(target)
    }
}
