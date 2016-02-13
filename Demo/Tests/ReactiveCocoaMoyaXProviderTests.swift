import Quick
import Nimble
import ReactiveCocoa
import MoyaX
import Alamofire

class ReactiveCocoaMoyaXProviderSpec: QuickSpec {
    override func spec() {
        var provider: ReactiveCocoaMoyaXProvider<GitHub>!
        beforeEach {
            let backend = StubBackend()
            provider = ReactiveCocoaMoyaXProvider<GitHub>(backend: backend)
        }

        describe("failing") {
            var provider: ReactiveCocoaMoyaXProvider<GitHub>!
            beforeEach {
                let backend = GenericStubBackend<GitHub>()
                backend.stub(.Zen, response: .NetworkError(NSError(domain: "com.moya.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Houston, we have a problem"])))

                provider = ReactiveCocoaMoyaXProvider<GitHub>(backend: backend)
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

                expect(errored).to(beTruthy())
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
                init(backend: BackendType,
                     plugins: [PluginType] = []) {

                    super.init(backend: backend, plugins: plugins)
                }

                override func request(token: Target, withCustomBackend backend: BackendType? = nil, completion: MoyaX.Completion) -> Cancellable {
                    return TestCancellable()
                }
            }

            var provider: ReactiveCocoaMoyaXProvider<GitHub>!
            beforeEach {
                TestCancellable.cancelled = false

                provider = TestProvider<GitHub>(backend: StubBackend(defaultBehavior: .Delayed(1)))
            }

            it("cancels network request when subscription is cancelled") {
                let target: GitHub = .Zen

                let disposable = provider.request(target).startWithCompleted { () -> Void in
                    // Should never be executed
                    fail()
                }
                disposable.dispose()

                expect(TestCancellable.cancelled).to(beTrue())
            }
        }

        describe("provider with SignalProducer") {

            it("returns a Response object") {
                var called = false

                provider.request(.Zen).startWithNext { (object) -> Void in
                    called = true
                }

                expect(called).to(beTruthy())
            }

            it("returns stubbed data for zen request") {
                var message: String?

                let target: GitHub = .Zen
                provider.request(target).startWithNext { (response) -> Void in
                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                }

                let sampleString = NSString(data: (target.sampleData as NSData), encoding: NSUTF8StringEncoding)
                expect(message).to(equal(sampleString))
            }

            it("returns correct data for user profile request") {
                var receivedResponse: NSDictionary?

                let target: GitHub = .UserProfile("ashfurrow")
                provider.request(target).startWithNext { (response) -> Void in
                    receivedResponse = try! NSJSONSerialization.JSONObjectWithData(response.data, options: []) as? NSDictionary
                }

                let sampleData = target.sampleData as NSData
                let sampleResponse: NSDictionary = try! NSJSONSerialization.JSONObjectWithData(sampleData, options: []) as! NSDictionary
                expect(receivedResponse).toNot(beNil())
                expect(receivedResponse) == sampleResponse
            }

            describe("a subsclassed reactive provider that tracks cancellation with delayed stubs") {
                struct TestCancellable: Cancellable {
                    static var cancelled = false

                    func cancel() {
                        TestCancellable.cancelled = true
                    }
                }

                class TestProvider<Target: TargetType>: ReactiveCocoaMoyaXProvider<Target> {
                    init(backend: BackendType,
                         plugins: [PluginType] = []) {

                        super.init(backend: backend, plugins: plugins)
                    }

                    override func request(token: Target, withCustomBackend backend: BackendType? = nil, completion: MoyaX.Completion) -> Cancellable {
                        return TestCancellable()
                    }
                }

                var provider: ReactiveCocoaMoyaXProvider<GitHub>!

                beforeEach {
                    TestCancellable.cancelled = false

                    provider = TestProvider<GitHub>(backend: StubBackend(defaultBehavior: .Delayed(1)))
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

            describe("provider with a TestScheduler") {
                var testScheduler: TestScheduler! = nil
                var response: MoyaX.Response? = nil

                beforeEach {
                    testScheduler = TestScheduler()

                    let backend = ReactiveCocoaGenericStubBackend<GitHub>(scheduler: testScheduler)
                    provider = ReactiveCocoaMoyaXProvider<GitHub>(backend: backend)

                    provider.request(.Zen).startWithNext { next in
                        response = next
                    }
                }

                afterEach {
                    response = nil
                }

                it("sends the stub when the test scheduler is advanced") {
                    testScheduler.run()
                    expect(response).toNot(beNil())
                }

                it("does not send the stub when the test scheduler is not advanced") {
                    expect(response).to(beNil())
                }
            }
        }
    }
}
