import Foundation
import MoyaX

// MARK: - Provider setup

public enum GitHub {
    case zen
    case userProfile(String)
    case userRepositories(String)
}

extension GitHub: Target {
    public var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    public var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .userProfile(let name):
            return "/users/\(name.URLEscapedString)"
        case .userRepositories(let name):
            return "/users/\(name.URLEscapedString)/repos"
        }
    }
    public var parameters: [String: AnyObject]? {
        switch self {
        case .userRepositories(_):
            return ["sort": "pushed"]
        default:
            return nil
        }
    }
}
