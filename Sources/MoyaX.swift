import Foundation

/// Closure type for Provider's completion
public typealias Completion = Result<Response, Error> -> ()

/**
    HTTP method definitions.
    See https://tools.ietf.org/html/rfc7231#section-4.3
*/
public enum HTTPMethod: String {
    case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}

/**
    Used to specify the way to encoding parameters.

    - URL: Encodes parameter to a query string to be set as or appended to any existing URL query for
           `GET`, `HEAD`, and `DELETE` requests, or set as the body for requests with any other HTTP method.
            The `Content-Type` HTTP header field of an encoded request with HTTP body is set to
           `application/x-www-form-urlencoded; charset=utf-8`. Since there is no published specification
           for how to encode collection types, the convention of appending `[]` to the key for array
           values (`foo[]=1&foo[]=2`), and appending the key surrounded by square brackets for nested
           dictionary values (`foo[bar]=baz`).
    - MultipartFormData: Encodes parameters to `multipart/form-data` for uploads within an HTTP or HTTPS body.
    - JSON: Encodes parameters by using `NSJSONSerialization`, which is set as the body of the request.
            The `Content-Type` HTTP header field of an encoded request is set to `application/json`.
*/
public enum ParameterEncoding {
    case URL
    case MultipartFormData
    case JSON
}

/**
    Used to create a multipart form data object for parameters.

    File name and MIME type is required for all cases.
    For information on MIME type, see http://www.iana.org/assignments/media-types/media-types.xhtml

    - Data: For NSData
    - File: For NSURL of a file
    - Stream: For NSInputStream
*/
public enum MultipartFormData {
    case Data(NSData, fileName: String, mimeType: String)
    case File(NSURL, fileName: String, mimeType: String)
    case Stream(NSInputStream, length: UInt64, fileName: String, mimeType: String)
}

/// Protocol to define the base URL, path, method, parameters and etc. for a target.
public protocol TargetType {
    /// Required
    var baseURL: NSURL { get }
    /// Required
    var path: String { get }
    /// Optional, default is `.GET`
    var method: HTTPMethod { get }

    /// Optional, default is `[:]`
    var headerFields: [String: String] { get }

    /// Optional, default is `[:]`
    var parameters: [String: AnyObject] { get }
    /// Optional, default is `.URL`, for multipart uploading, use `.MultipartFormData`
    var parameterEncoding: ParameterEncoding { get }

    /// Full path of the target, default is equivalent to `baseURL.URLByAppendingPathComponent(path)`,
    /// can be overridden for advanced usage
    var fullURL: NSURL { get }

    /// Returns an endpoint instance computed by the target,
    /// can be overridden for advanced usage
    var endpoint: Endpoint { get }
}

public extension TargetType {
    var method: HTTPMethod {
        return .GET
    }

    var headerFields: [String: String] {
        return [:]
    }

    var parameters: [String: AnyObject] {
        return [:]
    }
    var parameterEncoding: ParameterEncoding {
        return .URL
    }

    var fullURL: NSURL {
        return self.baseURL.URLByAppendingPathComponent(self.path)
    }

    var endpoint: Endpoint {
        return Endpoint(target: self)
    }
}

/// Protocol to define a middleware that can be regiestered to provider
public protocol MiddlewareType {
    /**
        Will be called before the endpoint be passed to backend.

        - Parameters:
            - target: The target instance which being requested
            - endpoint: The intermediate representation of target, modify it will cause side-effect
    */
    func willSendRequest(target: TargetType, endpoint: Endpoint)

    /**
        Will be called before calling completion closure.

        - Parameters:
            - target: The target instance which being requested
            - response: The result of the request
    */
    func didReceiveResponse(target: TargetType, response: Result<Response, Error>)
}

/// Protocol to define a backend which handle transform endpoint to request and perform it.
public protocol BackendType: class {
    func request(endpoint: Endpoint, completion: Completion) -> Cancellable
}

/// Protocol to define the opaque type returned from a request
public protocol Cancellable: CustomDebugStringConvertible {
    func cancel()
    var debugDescription: String { get }
}

/// A fake Cancellable implementation for request which aborted by setting `endpoint.shouldPerform = false`
internal final class AbortingCancellableToken: Cancellable {
    func cancel() {}

    var debugDescription: String {
        return "Stub CancellableToken for a aborting task."
    }
}
