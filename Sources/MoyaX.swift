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
    - Custom: Uses the associated closure value to construct a new request given an existing request and
              parameters.
*/

public enum ParameterEncoding {
    case URL
    case MultipartFormData
    case JSON
    case Custom((NSMutableURLRequest, [String:AnyObject]) -> (NSMutableURLRequest, NSError?))
}

/// Protocol to define the base URL, path, method, parameters and etc. for a target.
public protocol Target {
    /// Required
    var baseURL: NSURL { get }
    /// Required
    var path: String { get }
    /// Optional, default is `.GET`
    var method: HTTPMethod { get }

    /// Optional, default is `[:]`
    var headerFields: [String:String] { get }

    /// Optional, default is `[:]`
    var parameters: [String:AnyObject] { get }
    /// Optional, default is `.URL`, for multipart uploading, use `.MultipartFormData`
    var parameterEncoding: ParameterEncoding { get }

    /// Full path of the target, default is equivalent to `baseURL.URLByAppendingPathComponent(path)`,
    /// can be overridden for advanced usage
    var fullURL: NSURL { get }

    /// Returns an endpoint instance computed by the target,
    /// can be overridden for advanced usage
    var endpoint: Endpoint { get }
}

public extension Target {
    var method: HTTPMethod {
        return .GET
    }

    var headerFields: [String:String] {
        return [:]
    }

    var parameters: [String:AnyObject] {
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
public protocol Middleware {
    /**
        Will be called before the endpoint be passed to backend.

        - Parameters:
            - target: The target instance which being requested
            - endpoint: The intermediate representation of target, modify it will cause side-effect
    */
    func willSendRequest(target: Target, endpoint: Endpoint)

    /**
        Will be called before calling completion closure.

        - Parameters:
            - target: The target instance which being requested
            - response: The result of the request
    */
    func didReceiveResponse(target: Target, response: Result<Response, Error>)
}

/// Protocol to define a backend which handle transform endpoint to request and perform it.
public protocol Backend: class {
    func request(endpoint: Endpoint, completion: Completion) -> CancellableToken
}

/// Protocol to define the opaque type returned from a request
public protocol CancellableToken: CustomDebugStringConvertible {
    func cancel()

    var debugDescription: String { get }
}

/**
    Protocol to define a MultipartFormData parameter.
    The implementation must be a class because the value of Target#parameters is AnyObject.
*/
public protocol MultipartFormData: class, CustomStringConvertible, CustomDebugStringConvertible {}

/**
    Class to define a MultipartFormData parameter from a data.

    The body part data will be encoded using the following format:

    - `Content-Disposition: form-data; name=#{name}; filename=#{filename}` (HTTP Header)
    - `Content-Type: #{mimeType}` (HTTP Header)
    - Encoded file data
    - Multipart form boundary
*/
public class DataForMultipartFormData: MultipartFormData {
    let data: NSData
    let fileName: String?
    let mimeType: String?

    /**
        - parameter data: The data to encode into the multipart form data.
    */
    public init(data: NSData) {
        self.data = data

        self.fileName = nil
        self.mimeType = nil
    }

    /**
        - parameter data:     The data to encode into the multipart form data.
        - parameter fileName: The filename to associate with the data in the `Content-Disposition` HTTP header.
        - parameter mimeType: The MIME type to associate with the data in the `Content-Type` HTTP header.
    */
    public init(data: NSData, fileName: String, mimeType: String) {
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }

    public var description: String {
        var str = "#<DataForMultipartFormData length=\"\(self.data.length)\""
        if let fileName = self.fileName {
            str += " fileName=\"\(fileName)\""
        }
        if let mimeType = self.mimeType {
            str += " mimeType=\"\(mimeType)\""
        }
        str += ">"

        return str
    }

    /**
        The textual representation used when written to an output stream, which includes the data's length,
        as well as the file name and the MIME type if they have provided.
    */
    public var debugDescription: String {
        return description
    }
}

/**
    Class to define a MultipartFormData parameter from a file.

    The body part data will be encoded using the following format:

    - Content-Disposition: form-data; name=#{name}; filename=#{filename} (HTTP Header)
    - Content-Type: #{mimeType} (HTTP Header)
    - Encoded file data
    - Multipart form boundary
*/
public class FileURLForMultipartFormData: MultipartFormData {
    let fileURL: NSURL
    let fileName: String?
    let mimeType: String?

    /**
        - parameter fileURL: The URL of the file whose content will be encoded into the multipart form data.
    */
    public init(fileURL: NSURL) {
        self.fileURL = fileURL

        self.fileName = nil
        self.mimeType = nil
    }

    /**
        - parameter fileURL:  The URL of the file whose content will be encoded into the multipart form data.
        - parameter fileName: The filename to associate with the file content in the `Content-Disposition` HTTP header.
        - parameter mimeType: The MIME type to associate with the file content in the `Content-Type` HTTP header.
    */
    public init(fileURL: NSURL, fileName: String, mimeType: String) {
        self.fileURL = fileURL
        self.fileName = fileName
        self.mimeType = mimeType
    }

    /**
        The textual representation used when written to an output stream, which includes the file's URL,
        as well as the file name and the MIME type if they have provided.
    */
    public var description: String {
        var str = "#<FileURLForMultipartFormData fileURL=\"\(self.fileURL)\""
        if let fileName = self.fileName {
            str += " fileName=\"\(fileName)\""
        }
        if let mimeType = self.mimeType {
            str += " mimeType=\"\(mimeType)\""
        }
        str += ">"

        return str
    }

    public var debugDescription: String {
        return description
    }
}
