import Foundation

/**
    HTTP method definitions.
    See https://tools.ietf.org/html/rfc7231#section-4.3
*/
public enum Method: String {
    case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}

// MARK: ParameterEncoding

/**
    Used to specify the way in which a set of parameters are applied to a URL request.
    - `URL`:             Creates a query string to be set as or appended to any existing URL query for `GET`, `HEAD`,
                         and `DELETE` requests, or set as the body for requests with any other HTTP method. The
                         `Content-Type` HTTP header field of an encoded request with HTTP body is set to
                         `application/x-www-form-urlencoded; charset=utf-8`. Since there is no published specification
                         for how to encode collection types, the convention of appending `[]` to the key for array
                         values (`foo[]=1&foo[]=2`), and appending the key surrounded by square brackets for nested
                         dictionary values (`foo[bar]=baz`).
    - `URLEncodedInURL`: Creates query string to be set as or appended to any existing URL query. Uses the same
                         implementation as the `.URL` case, but always applies the encoded result to the URL.
    - `JSON`:            Uses `NSJSONSerialization` to create a JSON representation of the parameters object, which is
                         set as the body of the request. The `Content-Type` HTTP header field of an encoded request is
                         set to `application/json`.
    - `PropertyList`:    Uses `NSPropertyListSerialization` to create a plist representation of the parameters object,
                         according to the associated format and write options values, which is set as the body of the
                         request. The `Content-Type` HTTP header field of an encoded request is set to
                         `application/x-plist`.
    - `Custom`:          Uses the associated closure value to construct a new request given an existing request and
                         parameters.
*/
public enum ParameterEncoding {
    case URL
    case URLEncodedInURL
    case JSON
    case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
    case Custom((NSMutableURLRequest, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?))
}

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Method { get }
    var parameters: [String: AnyObject]? { get }

    var fullURL: NSURL { get }
    var endpoint: Endpoint { get }
}

public extension TargetType {
    var fullURL: NSURL {
        return self.baseURL.URLByAppendingPathComponent(self.path)
    }

    var endpoint: Endpoint {
        return Endpoint(URL: self.fullURL, method: self.method, parameters: self.parameters)
    }
}

public protocol BackendType {
    func request(request: NSURLRequest, completion: ((response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> ())) -> Cancellable
}

/// Protocol to define the opaque type returned from a request
public protocol Cancellable {
    func cancel()
}
