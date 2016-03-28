import Foundation

public enum Error: ErrorType {
    case BackendResponse(ErrorType)
    case BackendUnexpect(ErrorType)
    case Abort
    case Cancelled
    case Underlying(ErrorType)
}
