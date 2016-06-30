import XCTest
import OHHTTPStubs
@testable import MoyaX

class ProviderTests: XCTestCase {
    let data = "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!
    let path = "/test"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testRequest() {
        // Given
        stub(isPath(self.path)) { _ in
            return OHHTTPStubsResponse(data: self.data, statusCode: 200, headers: nil).responseTime(0.5)
        }

        var result: MoyaX.Result<MoyaX.Response, MoyaX.Error>?

        let provider = MoyaXProvider()

        let expectation = expectationWithDescription("do request")

        // When
        provider.request(SimpliestTarget(path: self.path)) {
            closureResult in
            result = closureResult
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2, handler: nil)
        // Then
        if let result = result {
            switch result {
            case .response:
                break
            default:
                XCTFail("the request should be success.")
            }
        } else {
            XCTFail("result should not be nil")
        }
    }

}
