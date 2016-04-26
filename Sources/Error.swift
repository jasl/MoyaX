import Foundation

/**
    Errors on requesting a target.

    - BackendBuildRequest: Raised on making request object. e.g serializing multipart form data failure
    - BackendResponse: Raised on backend's completion of a request. e.g timeout
    - BackendUnexpect: All other errors raised by backend
    - Cancelled: Raised by `cancellableToken.cancel()`
    = Underlying: Uncategoried errors
*/
public enum Error: ErrorType {
    case BackendBuildRequest(ErrorType)
    case BackendResponse(ErrorType)
    case BackendUnexpect(ErrorType)
    case Cancelled
    case Underlying(ErrorType)
}
