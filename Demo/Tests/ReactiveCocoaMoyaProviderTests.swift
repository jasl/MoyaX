import Quick
import Nimble
import ReactiveCocoa
import MoyaX
import Alamofire

class ReactiveCocoaMoyaXProviderSpec: QuickSpec {
    override func spec() {
        var provider: ReactiveCocoaMoyaXProvider<GitHub>!

        beforeEach {
            provider = ReactiveCocoaMoyaXProvider<GitHub>()

            setupOHHTTPStubs(withDelay: 0)
        }

        afterEach {
            unloadOHHTTPStubs()
        }


        describe("provider with RACSignal") {

            it("returns a Response object") {
                var called = false

                provider.request(.Zen).subscribeNext { (object) -> Void in
                    if let _ = object as? MoyaX.Response {
                        called = true
                    }
                }

                expect(called).toEventually(beTruthy())
            }

            it("returns correct data for user profile request") {
                var receivedResponse: NSDictionary?

                let target: GitHub = .UserProfile("ashfurrow")
                provider.request(target).subscribeNext { (object) -> Void in
                    if let response = object as? MoyaX.Response {
                        receivedResponse = try! NSJSONSerialization.JSONObjectWithData(response.data, options: []) as? NSDictionary
                    }
                }

                let sampleData = "{\"login\": \"ashfurrow\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!
                let sampleResponse = try! NSJSONSerialization.JSONObjectWithData(sampleData, options: []) as! NSDictionary

                expect(receivedResponse).toEventually(equal(sampleResponse))
            }
        }

        describe("failing") {
            beforeEach {
                setupOHHTTPStubsWithFailure()
            }

            it("returns the correct error message") {
                var receivedError: MoyaX.Error?

                waitUntil { done in
                    provider.request(.Zen).startWithFailed { (error) -> Void in
                        receivedError = error
                        done()
                    }
                }

                switch receivedError {
                case .Some(.Underlying(let error as NSError)):
                    expect(error.localizedDescription) == "Houston, we have a problem"
                default:
                    fail("expected an Underlying error that Houston has a problem")
                }
            }

            it("returns an error") {
                var errored = false

                let target: GitHub = .Zen
                provider.request(target).startWithFailed { (error) -> Void in
                    errored = true
                }

                expect(errored).toEventually(beTruthy())
            }
        }

        describe("a subsclassed reactive provider that tracks cancellation with delayed stubs") {
            struct TestCancellable: Cancellable {
                static var cancelled = false

                func cancel() {
                    TestCancellable.cancelled = true
                }
            }

            class TestProvider<Target: TargetType>: ReactiveCocoaMoyaXProvider<Target> {
                init(endpointClosure: EndpointClosure = MoyaX.DefaultEndpointMapping,
                     requestClosure: RequestClosure = MoyaX.DefaultRequestMapping,
                     manager: Manager = Alamofire.Manager.sharedInstance,
                     plugins: [PluginType] = []) {

                        super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, manager: manager, plugins: plugins)
                }

                override func request(token: Target, completion: MoyaX.Completion) -> Cancellable {
                    return TestCancellable()
                }
            }

            var provider: ReactiveCocoaMoyaXProvider<GitHub>!
            beforeEach {
                TestCancellable.cancelled = false

                setupOHHTTPStubs(withDelay: 1)

                provider = TestProvider<GitHub>()
            }

            it("cancels network request when subscription is cancelled") {
                let target: GitHub = .Zen

                let disposable = provider.request(target).startWithCompleted { () -> Void in
                    // Should never be executed
                    fail()
                }
                disposable.dispose()

                expect(TestCancellable.cancelled).toEventually(beTrue())
            }
        }

        describe("provider with SignalProducer") {

            it("returns a Response object") {
                var called = false

                provider.request(.Zen).startWithNext { (object) -> Void in
                    called = true
                }

                expect(called).toEventually(beTruthy())
            }

            it("returns stubbed data for zen request") {
                var message: String?

                let target: GitHub = .Zen
                provider.request(target).startWithNext { (response) -> Void in
                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                }

                let sampleString = NSString(data: ("Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!), encoding: NSUTF8StringEncoding)
                expect(message).toEventually(equal(sampleString))
            }

            it("returns correct data for user profile request") {
                var receivedResponse: NSDictionary?

                let target: GitHub = .UserProfile("ashfurrow")
                provider.request(target).startWithNext { (response) -> Void in
                    receivedResponse = try! NSJSONSerialization.JSONObjectWithData(response.data, options: []) as? NSDictionary
                }

                let sampleData = "{\"login\": \"ashfurrow\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!
                let sampleResponse: NSDictionary = try! NSJSONSerialization.JSONObjectWithData(sampleData, options: []) as! NSDictionary
                expect(receivedResponse).toEventuallyNot(beNil())
                expect(receivedResponse).toEventually(equal(sampleResponse))
            }

            describe("a subsclassed reactive provider that tracks cancellation") {
                struct TestCancellable: Cancellable {
                    static var cancelled = false

                    func cancel() {
                        TestCancellable.cancelled = true
                    }
                }

                class TestProvider<Target: TargetType>: ReactiveCocoaMoyaXProvider<Target> {
                    init(endpointClosure: EndpointClosure = MoyaX.DefaultEndpointMapping,
                         requestClosure: RequestClosure = MoyaX.DefaultRequestMapping,
                         manager: Manager = Alamofire.Manager.sharedInstance,
                         plugins: [PluginType] = []) {

                            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, manager: manager, plugins: plugins)
                    }

                    override func request(token: Target, completion: MoyaX.Completion) -> Cancellable {
                        return TestCancellable()
                    }
                }

                var provider: ReactiveCocoaMoyaXProvider<GitHub>!
                beforeEach {
                    TestCancellable.cancelled = false

                    provider = TestProvider<GitHub>()

                    setupOHHTTPStubs(withDelay: 3)
                }

                it("cancels network request when subscription is cancelled") {
                    let target: GitHub = .Zen

                    let disposable = provider.request(target).startWithCompleted { () -> Void in
                        // Should never be executed
                        fail()
                    }
                    disposable.dispose()

                    expect(TestCancellable.cancelled).to( beTrue() )
                }
            }
        }
    }
}
