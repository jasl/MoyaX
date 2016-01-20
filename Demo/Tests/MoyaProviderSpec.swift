import Quick
import Nimble
import Alamofire
import MoyaX

class MoyaXProviderSpec: QuickSpec {
    override func spec() {
        var provider: MoyaXProvider<GitHub>!
        beforeEach {
            provider = MoyaXProvider<GitHub>(stubClosure: MoyaX.ImmediatelyStub)
        }

        it("returns stubbed data for zen request") {
            var message: String?

            let target: GitHub = .Zen
            provider.request(target) { result in
                if case let .Success(response) = result {
                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                }
            }

            let sampleData = target.sampleData as NSData
            expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
        }

        it("returns stubbed data for user profile request") {
            var message: String?

            let target: GitHub = .UserProfile("ashfurrow")
            provider.request(target) { result in
                if case let .Success(response) = result {
                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                }
            }

            let sampleData = target.sampleData as NSData
            expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
        }

        it("returns equivalent Endpoint instances for the same target") {
            let target: GitHub = .Zen

            let endpoint1 = provider.endpoint(target)
            let endpoint2 = provider.endpoint(target)
            expect(endpoint1.urlRequest).to(equal(endpoint2.urlRequest))
        }

        it("returns a cancellable object when a request is made") {
            let target: GitHub = .UserProfile("ashfurrow")

            let cancellable: Cancellable = provider.request(target) { _ in  }

            expect(cancellable).toNot(beNil())

        }

        it("uses a custom manager by default, startRequestsImmediately should be false") {
            expect(provider.manager).toNot(beNil())
            expect(provider.manager.startRequestsImmediately) == false
        }

        it("credential closure returns nil") {
            var called = false
            let plugin = CredentialsPlugin { (target) -> NSURLCredential? in
                called = true
                return nil
            }

            let provider = MoyaXProvider<HTTPBin>(stubClosure: MoyaX.ImmediatelyStub, plugins: [plugin])
            let target: HTTPBin = .BasicAuth
            provider.request(target) { _ in  }

            expect(called) == true
        }

        it("credential closure returns valid username and password") {
            var called = false
            let plugin = CredentialsPlugin { (target) -> NSURLCredential? in
                called = true
                return NSURLCredential(user: "user", password: "passwd", persistence: .None)
            }

            let provider = MoyaXProvider<HTTPBin>(stubClosure: MoyaX.ImmediatelyStub, plugins: [plugin])
            let target: HTTPBin = .BasicAuth
            provider.request(target) { _ in  }

            expect(called) == true
        }

        it("accepts a custom Alamofire.Manager") {
            let manager = Manager()
            let provider = MoyaXProvider<GitHub>(manager: manager)

            expect(provider.manager).to(beIdenticalTo(manager))
        }

        it("notifies at the beginning of network requests") {
            var called = false
            let plugin = NetworkActivityPlugin { (change) -> () in
                if change == .Began {
                    called = true
                }
            }

            let provider = MoyaXProvider<GitHub>(stubClosure: MoyaX.ImmediatelyStub, plugins: [plugin])
            let target: GitHub = .Zen
            provider.request(target) { _ in  }

            expect(called) == true
        }

        it("notifies at the end of network requests") {
            var called = false
            let plugin = NetworkActivityPlugin { (change) -> () in
                if change == .Ended {
                    called = true
                }
            }

            let provider = MoyaXProvider<GitHub>(stubClosure: MoyaX.ImmediatelyStub, plugins: [plugin])
            let target: GitHub = .Zen
            provider.request(target) { _ in  }

            expect(called) == true
        }

        it("delays execution when appropriate") {
            let provider = MoyaXProvider<GitHub>(stubClosure: MoyaX.DelayedStub(2))
            let startDate = NSDate()
            var endDate: NSDate?
            let target: GitHub = .Zen
            waitUntil(timeout: 3) { done in
                provider.request(target) { _ in
                    endDate = NSDate()
                    done()
                }
                return
            }

            expect(endDate?.timeIntervalSinceDate(startDate)).to( beGreaterThanOrEqualTo(NSTimeInterval(2)) )
        }

        describe("a provider with a custom endpoint resolver") {
            var provider: MoyaXProvider<GitHub>!
            var executed = false

            beforeEach {
                executed = false
                let endpointResolution = { (endpoint: Endpoint, done: NSURLRequest -> Void) in
                    executed = true
                    done(endpoint.urlRequest)
                }
                provider = MoyaXProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaX.ImmediatelyStub)
            }

            it("executes the endpoint resolver") {
                let target: GitHub = .Zen
                provider.request(target) { _ in  }

                expect(executed).to(beTruthy())
            }
        }

        describe("with stubbed errors") {
            var provider: MoyaXProvider<GitHub>!
            beforeEach {
                provider = MoyaXProvider(endpointClosure: failureEndpointClosure, stubClosure: MoyaX.ImmediatelyStub)
            }

            it("returns stubbed data for zen request") {
                var errored = false
                let target: GitHub = .Zen

                waitUntil { done in
                    provider.request(target) { result in
                        if case .Failure = result {
                            errored = true
                        }
                        done()
                    }
                }

                let _ = target.sampleData
                expect(errored) == true
            }

            it("returns stubbed data for user profile request") {
                var errored = false

                let target: GitHub = .UserProfile("ashfurrow")
                waitUntil { done in
                    provider.request(target) { result in
                        if case .Failure = result {
                            errored = true
                        }
                        done()
                    }
                }

                let _ = target.sampleData
                expect(errored) == true
            }

            it("returns stubbed error data when present") {
                var receivedError: MoyaX.Error?

                let target: GitHub = .UserProfile("ashfurrow")
                provider.request(target) { result in
                    if case let .Failure(error) = result {
                        receivedError = error
                    }
                }

                switch receivedError {
                case .Some(.Underlying(let error as NSError)):
                    expect(error.localizedDescription) == "Houston, we have a problem"
                default:
                    fail("expected an Underlying error that Houston has a problem")
                }
            }
        }
    }
}
