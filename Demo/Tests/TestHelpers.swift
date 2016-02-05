import MoyaX
import Foundation
import OHHTTPStubs

extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
}

enum GitHub {
    case Zen
    case UserProfile(String)
}

extension GitHub: TargetType {
    var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        }
    }
    var method: MoyaX.Method {
        return .GET
    }
    var parameters: [String: AnyObject]? {
        return nil
    }
}

func setupOHHTTPStubs(withDelay responseTime: Double = 0.5) {
    OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/zen"}) { _ in
        return OHHTTPStubsResponse(data: "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!, statusCode: 200, headers: nil).responseTime(responseTime)
    }

    OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/users/ashfurrow"}) { _ in
        return OHHTTPStubsResponse(data: "{\"login\": \"ashfurrow\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!, statusCode: 200, headers: nil).responseTime(responseTime)
    }

    OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/basic-auth/user/passwd"}) { _ in
        return OHHTTPStubsResponse(data: "{\"authenticated\": true, \"user\": \"user\"}".dataUsingEncoding(NSUTF8StringEncoding)!, statusCode: 200, headers: nil).responseTime(responseTime)
    }
}

func unloadOHHTTPStubs() {
    OHHTTPStubs.removeAllStubs()
}

func setupOHHTTPStubsWithFailure(withDelay responseTime: Double = 0.5) {
    let error = NSError(domain: "com.moya.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Houston, we have a problem"])

    OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/zen"}) { _ in
        return OHHTTPStubsResponse(error: error).responseTime(responseTime)
    }

    OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/users/ashfurrow"}) { _ in
        return OHHTTPStubsResponse(error: error).responseTime(responseTime)
    }

    OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/basic-auth/user/passwd"}) { _ in
        return OHHTTPStubsResponse(error: error).responseTime(responseTime)
    }
}

func url(route: TargetType) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString
}

enum HTTPBin: TargetType {
    case BasicAuth

    var baseURL: NSURL { return NSURL(string: "http://httpbin.org")! }
    var path: String {
        switch self {
        case .BasicAuth:
            return "/basic-auth/user/passwd"
        }
    }

    var method: MoyaX.Method {
        return .GET
    }
    var parameters: [String: AnyObject]? {
        switch self {
        default:
            return [:]
        }
    }
}
