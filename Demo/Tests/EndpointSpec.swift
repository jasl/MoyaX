import Quick
import MoyaX
import Nimble

extension MoyaX.ParameterEncoding: Equatable {}

public func ==(lhs: MoyaX.ParameterEncoding, rhs: MoyaX.ParameterEncoding) -> Bool {
    switch (lhs, rhs) {
    case (.URL, .URL):
        return true
    case (.JSON, .JSON):
        return true
    case (.PropertyList(_), .PropertyList(_)):
        return true
    case (.Custom(_), .Custom(_)):
        return true
    default:
        return false
    }
}

class EndpointSpec: QuickSpec {
    override func spec() {
        describe("an endpoint") {
            var endpoint: Endpoint!

            beforeEach {
                let target: GitHub = .Zen
                let parameters = ["Nemesis": "Harvey"]
                let headerFields = ["Title": "Dominar"]

                endpoint = Endpoint(URL: url(target), method: MoyaX.Method.GET, parameters: parameters, parameterEncoding: .JSON, headerFields: headerFields)
            }

            it("returns a correct URL request") {
                let request = endpoint.mutableURLRequest
                expect(request.URL!.absoluteString).to(equal("https://api.github.com/zen"))
                expect(NSString(data: request.HTTPBody!, encoding: 4)).to(equal("{\"Nemesis\":\"Harvey\"}"))
                let titleObject: AnyObject? = endpoint.headerFields?["Title"]
                let title = titleObject as? String
                expect(title).to(equal("Dominar"))
            }
        }
    }
}
