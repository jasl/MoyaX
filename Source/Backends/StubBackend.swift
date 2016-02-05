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
    let endpoint: Endpoint
    let behavior: StubBehavior
    let response: StubResponse

    public init(endpoint: Endpoint, behavior: StubBehavior, response: StubResponse) {
        self.endpoint = endpoint
        self.behavior = behavior
        self.response = response
    }
}

internal final class StubCancellableToken: Cancellable {
    private(set) var isCancelled = false

    func cancel() {
        self.isCancelled = true
    }
}

public class StubBackend: BackendType {
    private var stubs: [NSURL: StubRule]

    public init() {
        self.stubs = [:]
    }

    public func stubTarget(target: TargetType, behavior: StubBehavior, response: StubResponse) {
        let endpoint = target.endpoint

        self.stubs[endpoint.URL] = StubRule(endpoint: endpoint, behavior: behavior, response: response)
    }

    public func removeAllStubs() {
        self.stubs = [:]
    }

    public func request(request: NSURLRequest, completion: (response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> ()) -> Cancellable {
        guard let stubRule = self.stubs[request.URL!] else {
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
            let response = NSHTTPURLResponse(URL: rule.endpoint.URL, statusCode: statusCode, HTTPVersion: nil, headerFields: nil)
            completion(response: response, data: data, error: nil)
        case .NetworkError(let error):
            completion(response: nil, data: nil, error: error)
        }
    }
}
