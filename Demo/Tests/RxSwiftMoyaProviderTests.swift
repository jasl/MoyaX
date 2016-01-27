import Quick
import Nimble
import MoyaX
import RxSwift
import Alamofire

class RxSwiftMoyaXProviderSpec: QuickSpec {
    override func spec() {
        
        describe("provider with Observable") {
            
            var provider: RxMoyaXProvider<GitHub>!
            
            beforeEach {
                provider = RxMoyaXProvider(stubClosure: MoyaXProvider.ImmediatelyStub)
            }
            
            it("returns a Response object") {
                var called = false
                
                _ = provider.request(.Zen).subscribeNext { (object) -> Void in
                    called = true
                }
                
                expect(called).to(beTruthy())
            }
            
            it("returns stubbed data for zen request") {
                var message: String?
                
                let target: GitHub = .Zen
                _ = provider.request(target).subscribeNext { (response) -> Void in
                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                }
                
                let sampleString = NSString(data: (target.sampleData as NSData), encoding: NSUTF8StringEncoding)
                expect(message).to(equal(sampleString))
            }
            
            it("returns correct data for user profile request") {
                var receivedResponse: NSDictionary?
                
                let target: GitHub = .UserProfile("ashfurrow")
                _ = provider.request(target).subscribeNext { (response) -> Void in
                    receivedResponse = try! NSJSONSerialization.JSONObjectWithData(response.data, options: []) as? NSDictionary
                }
                
                expect(receivedResponse).toNot(beNil())
            }
        }
        
        describe("failing") {
            var provider: RxMoyaXProvider<GitHub>!
            beforeEach {
                provider = RxMoyaXProvider<GitHub>(endpointClosure: failureEndpointClosure, stubClosure: MoyaXProvider.ImmediatelyStub)
            }
            
            it("returns the correct error message") {
                var receivedError: MoyaX.Error?
                
                waitUntil { done in
                    _ = provider.request(.Zen).subscribeError { (error) -> Void in
                        receivedError = error as? MoyaX.Error
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
                _ = provider.request(target).subscribeError { (error) -> Void in
                    errored = true
                }
                
                expect(errored).to(beTruthy())
            }
        }
    }
}
