import Foundation
import ReactiveCocoa

public class ReactiveCocoaStubBackend: StubBackend {
    internal let scheduler: DateSchedulerType?

    public init(scheduler: DateSchedulerType? = nil, defaultBehavior: StubBehavior = .Immediate, defaultResponse: StubResponse = .NoStubError) {
        self.scheduler = scheduler
        super.init(defaultBehavior: defaultBehavior, defaultResponse: defaultResponse)
    }

    override public func request(request: NSURLRequest, target: TargetType, completion: (response:NSHTTPURLResponse?, data:NSData?, error:NSError?) -> ()) -> Cancellable {
        guard let scheduler = self.scheduler else {
            return super.request(request, target: target, completion: completion)
        }

        var dis: Disposable? = .None
        let cancellableToken = StubCancellableToken {
            dis?.dispose()
        }

        let action = StubAction(URL: target.fullURL, method: target.method)

        var response = (target as? TargetWithSampleType)?.sampleResponse ?? self.defaultResponse
        var behavior = self.defaultBehavior

        if let stubRule = self.stubs[action] {
            response = stubRule.conditionalResponse(request: request, target: target)
            behavior = stubRule.behavior ?? behavior
        }

        let stub = self.lazyStubResponseClosure(action.URL, response: response, cancellableToken: cancellableToken, completion: completion)

        switch behavior {
        case .Immediate:
            dis = scheduler.schedule(stub)
        case .Delayed(let delay):
            let date = NSDate(timeIntervalSinceNow: delay)
            dis = scheduler.scheduleAfter(date, action: stub)
        }

        return cancellableToken
    }

    internal final func lazyStubResponseClosure(URL: NSURL, response: StubResponse, cancellableToken: StubCancellableToken, completion: (response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> ()) -> (() -> ()) {
        return { self.stubResponse(URL, response: response, cancellableToken: cancellableToken, completion: completion) }
    }
}

public class ReactiveCocoaGenericStubBackend<Target: TargetType>: ReactiveCocoaStubBackend {
    public override init(scheduler: DateSchedulerType? = nil, defaultBehavior: StubBehavior = .Immediate, defaultResponse: StubResponse = .NoStubError) {
        super.init(scheduler: scheduler, defaultBehavior: defaultBehavior, defaultResponse: defaultResponse)
    }

    public func stub(target: Target, behavior: StubBehavior? = nil, response: StubResponse) {
        self.stubTarget(target, behavior: behavior, response: response)
    }

    public func stub(target: Target, behavior: StubBehavior? = nil, conditionalResponse: StubRule.ConditionalResponseClosure) {
        self.stubTarget(target, behavior: behavior, conditionalResponse: conditionalResponse)
    }

    public func removeStub(target: Target) {
        self.removeStubTarget(target)
    }
}

