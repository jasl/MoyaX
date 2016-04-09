import Foundation
import MoyaX

// MARK: - Provider setup

public enum GitHub {
    case Zen
    case UserProfile(String)
    case UserRepositories(String)
}

extension GitHub: Target {
    public var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    public var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        case .UserRepositories(let name):
            return "/users/\(name.URLEscapedString)/repos"
        }
    }
    public var parameters: [String: AnyObject]? {
        switch self {
        case .UserRepositories(_):
            return ["sort": "pushed"]
        default:
            return nil
        }
    }
}
