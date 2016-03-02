import Quick
import MoyaX
import Alamofire
import Nimble

extension MoyaX.ParameterEncoding: Equatable {}

public func == (lhs: MoyaX.ParameterEncoding, rhs: MoyaX.ParameterEncoding) -> Bool {
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
        var endpoint: Endpoint!

        let target: GitHub = .Zen
        let parameters = ["Nemesis": "Harvey"]
        let headerFields = ["Title": "Dominar"]

        describe("an endpoint") {
            it("returns a correct URL request") {

                endpoint = Endpoint(URL: target.fullURL, method: MoyaX.Method.GET, parameters: parameters, parameterEncoding: MoyaX.ParameterEncoding.JSON, headerFields: headerFields)

                let request = endpoint.encodedMutableURLRequest
                expect(request.URL!.absoluteString).to(equal("https://api.github.com/zen"))
                expect(NSString(data: request.HTTPBody!, encoding: 4)).to(equal("{\"Nemesis\":\"Harvey\"}"))
                let titleObject: AnyObject? = endpoint.headerFields["Title"]
                let title = titleObject as? String
                expect(title).to(equal("Dominar"))
            }
        }

        describe("encoding endpoint as Alamofire does") {
            it("encodes Endopoint by URL encoding") {
                endpoint = Endpoint(URL: target.fullURL, method: MoyaX.Method.GET, parameters: parameters, parameterEncoding: MoyaX.ParameterEncoding.URL, headerFields: headerFields)
                let requestWithoutEncodingParameters = endpoint.mutableURLRequest

                let encodedRequest = endpoint.encodedMutableURLRequest
                let alamofireEncodedRequest = Alamofire.ParameterEncoding.URL.encode(requestWithoutEncodingParameters, parameters: endpoint.parameters).0

                expect(encodedRequest).to(equal(alamofireEncodedRequest))
            }

            it("encodes Endopoint by JSON encoding") {
                endpoint = Endpoint(URL: target.fullURL, method: MoyaX.Method.GET, parameters: parameters, parameterEncoding: MoyaX.ParameterEncoding.JSON, headerFields: headerFields)
                let requestWithoutEncodingParameters = endpoint.mutableURLRequest

                let encodedRequest = endpoint.encodedMutableURLRequest
                let alamofireEncodedRequest = Alamofire.ParameterEncoding.JSON.encode(requestWithoutEncodingParameters, parameters: endpoint.parameters).0

                expect(encodedRequest).to(equal(alamofireEncodedRequest))
            }

            it("encodes Endopoint by PropertyList encoding") {
                endpoint = Endpoint(URL: target.fullURL, method: MoyaX.Method.GET, parameters: parameters, parameterEncoding: MoyaX.ParameterEncoding.PropertyList(NSPropertyListFormat.BinaryFormat_v1_0, 0), headerFields: headerFields)
                let requestWithoutEncodingParameters = endpoint.mutableURLRequest

                let encodedRequest = endpoint.encodedMutableURLRequest
                let alamofireEncodedRequest = Alamofire.ParameterEncoding.PropertyList(NSPropertyListFormat.BinaryFormat_v1_0, 0).encode(requestWithoutEncodingParameters, parameters: endpoint.parameters).0

                expect(encodedRequest).to(equal(alamofireEncodedRequest))
            }

            it("encodes Endopoint by Custom encoding") {
                var called: Bool = false

                let closureForMoyaX: (NSMutableURLRequest, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?) = { req, params in
                    called = true
                    return (NSMutableURLRequest(), nil)
                }

                let closureForAlamofire: (URLRequestConvertible, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?) = { req, params in
                    called = true
                    return (NSMutableURLRequest(), nil)
                }

                endpoint = Endpoint(URL: target.fullURL, method: MoyaX.Method.GET, parameters: parameters, parameterEncoding: MoyaX.ParameterEncoding.Custom(closureForMoyaX), headerFields: headerFields)
                let requestWithoutEncodingParameters = endpoint.mutableURLRequest

                let encodedRequest = endpoint.encodedMutableURLRequest
                let alamofireEncodedRequest = Alamofire.ParameterEncoding.Custom(closureForAlamofire).encode(requestWithoutEncodingParameters, parameters: endpoint.parameters).0

                expect(called).to(beTrue())
                expect(encodedRequest).to(equal(alamofireEncodedRequest))
            }
        }
    }
}
