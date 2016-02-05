import Foundation
import Result

/// A MoyaX Plugin receives callbacks to perform side effects wherever a request is sent or received.
///
/// for example, a plugin may be used to
///     - log network requests
///     - hide and show a network avtivity indicator
///     - inject additional information into a request
public protocol PluginType {
    /// Called immediately before a request is sent over the network (or stubbed).
    func willSendRequest(request: NSMutableURLRequest, target: TargetType)

    // Called after a response has been received, but before the MoyaXProvider has invoked its completion handler.
    func didReceiveResponse(result: Result<Response, Error>, target: TargetType)
}
