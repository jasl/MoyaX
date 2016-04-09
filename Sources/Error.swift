import Foundation

/**
    Errors on requesting a target.

    - BackendBuildingRequest: Raised on making request object. e.g raised by serializing multipart failure
    - BackendResponse: Raised on backend's completion of a request. e.g raised by request timeout
    - BackendUnexpect: All other errors raised by backend
    - Aborted: Raised by setting `endpoint.willPerform = false`
    - Cancelled: Raised by `cancellableToken.cancel()`
    = Underlying: Uncategoried errors
*/
public enum Error: ErrorType {
    case BackendBuildingRequest(ErrorType)
    case BackendResponse(ErrorType)
    case BackendUnexpect(ErrorType)
    case Aborted
    case Cancelled
    case Underlying(ErrorType)
}
