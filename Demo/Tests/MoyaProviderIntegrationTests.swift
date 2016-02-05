import Quick
import MoyaX
import Nimble
import Alamofire

func beIndenticalToResponse(expectedValue: MoyaX.Response) -> MatcherFunc<MoyaX.Response> {
    return MatcherFunc { actualExpression, failureMessage in
        do {
            let instance = try actualExpression.evaluate()
            return instance === expectedValue
        } catch {
            return false
        }
    }
}

class MoyaXProviderIntegrationTests: QuickSpec {
    override func spec() {
        let userMessage = NSString(data: "{\"login\": \"ashfurrow\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!, encoding: NSUTF8StringEncoding)
        let zenMessage = NSString(data: "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!, encoding: NSUTF8StringEncoding)

        beforeEach {
            setupOHHTTPStubs()
        }

        afterEach {
            unloadOHHTTPStubs()
        }

        describe("valid endpoints") {
            describe("with live data") {
                describe("a provider") {
                    var provider: MoyaXProvider<GitHub>!
                    beforeEach {
                        provider = MoyaXProvider<GitHub>()
                    }

                    it("returns real data for zen request") {
                        var message: String?

                        waitUntil { done in
                            provider.request(.Zen) { result in
                                if case let .Success(response) = result {
                                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                                }
                                done()
                            }
                        }

                        expect(message) == zenMessage
                    }

                    it("returns real data for user profile request") {
                        var message: String?

                        waitUntil { done in
                            let target: GitHub = .UserProfile("ashfurrow")
                            provider.request(target) { result in
                                if case let .Success(response) = result {
                                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                                }
                                done()
                            }
                        }

                        expect(message) == userMessage
                    }

                    it("returns an error when cancelled") {
                        var receivedError: ErrorType?

                        waitUntil { done in
                            let target: GitHub = .UserProfile("ashfurrow")
                            let token = provider.request(target) { result in
                                if case let .Failure(error) = result {
                                    receivedError = error
                                    done()
                                }
                            }
                            token.cancel()
                        }

                        expect(receivedError).toNot( beNil() )
                    }

                    it("uses a custom Alamofire.Manager request generation") {
                        let manager = StubManager()
                        let provider = MoyaXProvider<GitHub>(manager: manager)

                        waitUntil { done in
                            provider.request(GitHub.Zen) { _ in done() }
                        }

                        expect(manager.called) == true
                    }
                }

                describe("a provider with network activity plugin") {
                    it("notifies at the beginning of network requests") {
                        var called = false
                        let plugin = NetworkActivityPlugin { change in
                            if change == .Began {
                                called = true
                            }
                        }

                        let provider = MoyaXProvider<GitHub>(plugins: [plugin])
                        waitUntil { done in
                            provider.request(.Zen) { _ in done() }
                        }

                        expect(called) == true
                    }

                    it("notifies at the end of network requests") {
                        var called = false
                        let plugin = NetworkActivityPlugin { change in
                            if change == .Ended {
                                called = true
                            }
                        }

                        let provider = MoyaXProvider<GitHub>(plugins: [plugin])
                        waitUntil { done in
                            provider.request(.Zen) { _ in done() }
                        }

                        expect(called) == true
                    }
                }

                describe("a provider with network logger plugin") {
                    var log = ""
                    var plugin: NetworkLoggerPlugin!
                    beforeEach {
                        log = ""

                        plugin = NetworkLoggerPlugin(verbose: true, output: { printing in
                            //mapping the Any... from items to a string that can be compared
                            let stringArray: [String] = printing.items.map { $0 as? String }.flatMap { $0 }
                            let string: String = stringArray.reduce("") { $0 + $1 + " " }
                            log += string
                        })
                    }

                    it("logs the request") {

                        let provider = MoyaXProvider<GitHub>(plugins: [plugin])
                        waitUntil { done in
                            provider.request(GitHub.Zen) { _ in done() }
                        }

                        expect(log).to( contain("Request:") )
                        expect(log).to( contain("{ URL: https://api.github.com/zen }") )
                        expect(log).to( contain("Request Headers: [:]") )
                        expect(log).to( contain("HTTP Request Method: GET") )
                        expect(log).to( contain("Response:") )
                        expect(log).to( contain("{ URL: https://api.github.com/zen } { status code: 200, headers") )
                        expect(log).to( contain("\"Content-Length\" = 43;") )
                    }
                }

                describe("a reactive provider with RACSignal") {
                    var provider: ReactiveCocoaMoyaXProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaXProvider<GitHub>()
                    }

                    it("returns some data for zen request") {
                        var message: String?

                        waitUntil { done in
                            provider.request(GitHub.Zen).subscribeNext { response in
                                if let response = response as? MoyaX.Response {
                                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                                }

                                done()
                            }
                        }

                        expect(message) == zenMessage
                    }

                    it("returns some data for user profile request") {
                        var message: String?

                        waitUntil { done in
                            let target: GitHub = .UserProfile("ashfurrow")
                            provider.request(target).subscribeNext { response in
                                if let response = response as? MoyaX.Response {
                                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                                }

                                done()
                            }
                        }

                        expect(message) == userMessage
                    }
                }
            }

            describe("a reactive provider with SignalProducer") {
                var provider: ReactiveCocoaMoyaXProvider<GitHub>!
                beforeEach {
                    provider = ReactiveCocoaMoyaXProvider<GitHub>()
                }

                it("returns some data for zen request") {
                    var message: String?

                    waitUntil { done in
                        provider.request(.Zen).startWithNext { response in
                            message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            done()
                        }
                    }

                    expect(message) == zenMessage
                }

                it("returns some data for user profile request") {
                    var message: String?

                    waitUntil { done in
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).startWithNext { response in
                            message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            done()
                        }
                    }

                    expect(message) == userMessage
                }
            }
        }
    }
}

class StubManager: Manager {
    var called = false

    override func request(URLRequest: URLRequestConvertible) -> Request {
        called = true
        return super.request(URLRequest)
    }
}
