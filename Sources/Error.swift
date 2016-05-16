import Foundation

/**
    Errors on requesting a target.

    - backendBuildRequest: Raised on making request object. e.g serializing multipart form data failure
    - backendResponse: Raised on backend's completion of a request. e.g timeout
    - backendUnexpect: All other errors raised by backend
    - cancelled: Raised by `cancellableToken.cancel()`
    = underlying: Uncategoried errors
*/
public enum Error: ErrorType {
    case backendBuildRequest(ErrorType)
    case backendResponse(ErrorType)
    case backendUnexpect(ErrorType)
    case cancelled
    case underlying(ErrorType)
}
