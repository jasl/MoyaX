import XCTest
import Alamofire
@testable import MoyaX

class EndpointTests: XCTestCase {
    let target = TestTarget()
    var endpoint: Endpoint!

    override func setUp() {
        super.setUp()
        self.endpoint = Endpoint(target: self.target)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testMutableURLRequest() {
        let request = self.endpoint.mutableURLRequest

        XCTAssertEqual(request.URL, self.target.fullURL)
        XCTAssertEqual(request.HTTPMethod, "GET")
        XCTAssertEqual(request.allHTTPHeaderFields?["Title"], self.target.headerFields["Title"])
    }

    func testEncodedMutableURLRequestByURL() {
        let encodingForMoyaX = MoyaX.ParameterEncoding.URL
        let encodingForAlamofire = Alamofire.ParameterEncoding.URL

        self.endpoint.parameterEncoding = encodingForMoyaX

        XCTAssertEqual(self.endpoint.encodedMutableURLRequest, encodingForAlamofire.encode(self.endpoint.mutableURLRequest, parameters: self.target.parameters).0)
    }

    func testEncodedMutableURLRequestByURLEncodedInURL() {
        let encodingForMoyaX = MoyaX.ParameterEncoding.URLEncodedInURL
        let encodingForAlamofire = Alamofire.ParameterEncoding.URLEncodedInURL

        self.endpoint.parameterEncoding = encodingForMoyaX

        XCTAssertEqual(self.endpoint.encodedMutableURLRequest, encodingForAlamofire.encode(self.endpoint.mutableURLRequest, parameters: self.target.parameters).0)
    }

    func testEncodedMutableURLRequestByJSON() {
        let encodingForMoyaX = MoyaX.ParameterEncoding.JSON
        let encodingForAlamofire = Alamofire.ParameterEncoding.JSON

        self.endpoint.parameterEncoding = encodingForMoyaX

        XCTAssertEqual(self.endpoint.encodedMutableURLRequest, encodingForAlamofire.encode(self.endpoint.mutableURLRequest, parameters: self.target.parameters).0)
    }

    func testEncodedMutableURLRequestByPropertyList() {
        let encodingForMoyaX = MoyaX.ParameterEncoding.PropertyList(NSPropertyListFormat.BinaryFormat_v1_0, 0)
        let encodingForAlamofire = Alamofire.ParameterEncoding.PropertyList(NSPropertyListFormat.BinaryFormat_v1_0, 0)

        self.endpoint.parameterEncoding = encodingForMoyaX

        XCTAssertEqual(self.endpoint.encodedMutableURLRequest, encodingForAlamofire.encode(self.endpoint.mutableURLRequest, parameters: self.target.parameters).0)
    }

    func testEncodedMutableURLRequestByCustom() {
        var calledEncodingClosure = false

        let encodingClosureForMoyaX: (NSMutableURLRequest, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?) = { req, params in
            calledEncodingClosure = true
            return (req, nil)
        }

        let encodingClosureForAlamofire: (URLRequestConvertible, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?) = { req, params in
            return (req.URLRequest.mutableCopy() as! NSMutableURLRequest, nil)
        }

        let encodingForMoyaX = MoyaX.ParameterEncoding.Custom(encodingClosureForMoyaX)
        let encodingForAlamofire = Alamofire.ParameterEncoding.Custom(encodingClosureForAlamofire)

        self.endpoint.parameterEncoding = encodingForMoyaX

        XCTAssertEqual(self.endpoint.encodedMutableURLRequest, encodingForAlamofire.encode(self.endpoint.mutableURLRequest, parameters: self.target.parameters).0)
        XCTAssertTrue(calledEncodingClosure)
    }

}
