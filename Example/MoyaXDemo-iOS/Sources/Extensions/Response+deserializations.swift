import Foundation
import MoyaX

extension Response {
    /// Maps data received from the signal into a JSON object.
    func mapJSON() throws -> AnyObject {
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            throw Error.Underlying(error)
        }
    }

    /// Maps data received from the signal into a String.
    func mapString() throws -> String {
        guard let string = NSString(data: data, encoding: NSUTF8StringEncoding) else {
            throw Error.Underlying(NSError(domain: "MoyaX.Demo", code: -1001, userInfo: nil))
        }
        return string as String
    }
}
