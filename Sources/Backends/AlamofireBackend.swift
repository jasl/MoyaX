import Foundation
import Alamofire

internal final class AlamofireCancellableToken: CancellableToken {
    internal(set) var request: Alamofire.Request?
    private(set) var isCancelled: Bool = false

    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    init() {}

    init(request: Request) {
        self.request = request
    }

    func cancel() {
        OSSpinLockLock(&self.lock)
        defer { OSSpinLockUnlock(&self.lock) }
        if self.isCancelled { return }

        self.isCancelled = true
        request?.cancel()
    }

    var debugDescription: String {
        if let request = self.request {
            return "CancellableToken for Request: \(request.debugDescription)."
        } else {
            return "CancellableToken without a Request, maybe an upload request?"
        }
    }
}

/// The backend for Alamofire
public class AlamofireBackend: Backend {
    /// Default Alamofire manager for backend.
    public static let defaultManager: Manager = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 4

        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false

        return manager
    }()

    /// The Alamofire manager.
    let manager: Alamofire.Manager
    /// Called before starting request.
    let willPerformRequest: ((Endpoint, Alamofire.Request) -> ())?
    /// Called on Alamofire's response closure.
    let didReceiveResponse: ((Endpoint, Alamofire.Response<NSData, NSError>) -> ())?

    /// Default memory threshold used when encoding `MultipartFormData`.
    private static let MultipartFormDataEncodingMemoryThreshold: UInt64 = 10 * 1024 * 1024
    /// Memory threshold used when encoding `MultipartFormData`
    let multipartFormDataEncodingMemoryThreshold: UInt64

    /**
       Constructor of the backend.
    */
    public init(manager: Manager = defaultManager,
                multipartFormDataEncodingMemoryThreshold: UInt64 = MultipartFormDataEncodingMemoryThreshold,
                willPerformRequest: ((Endpoint, Alamofire.Request) -> ())? = nil,
                didReceiveResponse: ((Endpoint, Alamofire.Response<NSData, NSError>) -> ())? = nil) {
        self.manager = manager
        self.multipartFormDataEncodingMemoryThreshold = multipartFormDataEncodingMemoryThreshold
        self.willPerformRequest = willPerformRequest
        self.didReceiveResponse = didReceiveResponse
    }

    /**
        Encodes the endpoint to Alamofire's Request and perform it.
    */
    public func request(endpoint: Endpoint, completion: Completion) -> CancellableToken {
        let cancellableToken = AlamofireCancellableToken()

        let request = NSMutableURLRequest(URL: endpoint.URL)
        request.HTTPMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headerFields

        switch endpoint.parameterEncoding {
        case .URL, .JSON:
            let encodedRequest = self.encodeParameters(request, parameterEncoding: endpoint.parameterEncoding, parameters: endpoint.parameters).0
            let alamofireRequest = self.manager.request(encodedRequest)
            cancellableToken.request = alamofireRequest

            self.willPerformRequest?(endpoint, alamofireRequest)
            self.setResponseCompletion(alamofireRequest, endpoint: endpoint, completion: completion)

            if !self.manager.startRequestsImmediately {
                alamofireRequest.resume()
            }
        case .MultipartFormData:
            var components: [(String, String)] = []
            var multipartComponents: [String:MultipartFormData] = [:]

            for (key, value) in endpoint.parameters {
                if let multipartData = value as? MultipartFormData {
                    multipartComponents[key] = multipartData
                } else {
                    components += Alamofire.ParameterEncoding.URL.queryComponents(key, value)
                }
            }

            self.manager.upload(request,
                multipartFormData: { multipartFormData in
                for (key, value) in components {
                    multipartFormData.appendBodyPart(data: value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: key)
                }

                for (key, value) in multipartComponents {
                    switch value {
                    case let .Data(data, fileName, mimeType):
                        multipartFormData.appendBodyPart(data: data, name: key, fileName: fileName, mimeType: mimeType)
                    case let .File(fileURL, fileName, mimeType):
                        multipartFormData.appendBodyPart(fileURL: fileURL, name: key, fileName: fileName, mimeType: mimeType)
                    case let .Stream(stream, length, fileName, mimeType):
                        multipartFormData.appendBodyPart(stream: stream, length: length, name: key, fileName: fileName, mimeType: mimeType)
                    }
                }
            }, encodingMemoryThreshold: self.multipartFormDataEncodingMemoryThreshold,
                encodingCompletion: { result in
                switch result {
                case .Success(let request, _, _):
                    if cancellableToken.isCancelled {
                        completion(.Incomplete(Error.Cancelled))
                        return
                    }

                    cancellableToken.request = request

                    self.willPerformRequest?(endpoint, request)
                    self.setResponseCompletion(request, endpoint: endpoint, completion: completion)

                    if !self.manager.startRequestsImmediately {
                        request.resume()
                    }
                case .Failure(let error):
                    completion(.Incomplete(Error.BackendBuildingRequest(error)))
                }
            })
        }

        return cancellableToken
    }

    private func setResponseCompletion(request: Alamofire.Request, endpoint: Endpoint, completion: Completion) {
        request.responseData { alamofireResponse in
            self.didReceiveResponse?(endpoint, alamofireResponse)

            guard let rawResponse = alamofireResponse.response else {
                if case let .Failure(error) = alamofireResponse.result {
                    if error.code == NSURLErrorCancelled {
                        completion(.Incomplete(Error.Cancelled))
                    } else {
                        completion(.Incomplete(Error.BackendUnexpect(error)))
                    }
                } else {
                    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
                    completion(.Incomplete(Error.BackendUnexpect(error)))
                }

                return
            }

            switch alamofireResponse.result {
            case let .Success(data):
                let response = Response(statusCode: rawResponse.statusCode, data: data, response: rawResponse)
                completion(.Response(response))
            case let .Failure(error):
                completion(.Incomplete(Error.BackendResponse(error)))
            }
        }
    }

    private func encodeParameters(request: NSMutableURLRequest, parameterEncoding: ParameterEncoding, parameters: [String: AnyObject]) -> (NSMutableURLRequest, NSError?) {
        switch parameterEncoding {
        case .URL:
            return Alamofire.ParameterEncoding.URL.encode(request, parameters: parameters)
        case .JSON:
            return Alamofire.ParameterEncoding.JSON.encode(request, parameters: parameters)
        default:
            return (request, BackendError.errorWithCode(.UnsupportParameterEncoding, failureReason: "\(parameterEncoding) can't encode by Alamofire's ParameterEncoding."))
        }
    }
}

public extension AlamofireBackend {
    public struct BackendError {
        public static let Domain = "me.jasl.moyax.backend.alamofire.error"

        public enum Code: Int {
            case UnsupportParameterEncoding = -6000
            case EncodingComponentFailed = -6005
        }

        /**
            Creates an `NSError` with the given error code and failure reason.
            - parameter code:          The error code.
            - parameter failureReason: The failure reason.
            - returns: An `NSError` with the given error code and failure reason.
        */
        public static func errorWithCode(code: Code, failureReason: String) -> NSError {
            return errorWithCode(code.rawValue, failureReason: failureReason)
        }

        /**
            Creates an `NSError` with the given error code and failure reason.
            - parameter code:          The error code.
            - parameter failureReason: The failure reason.
            - returns: An `NSError` with the given error code and failure reason.
        */
        public static func errorWithCode(code: Int, failureReason: String) -> NSError {
            let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
            return NSError(domain: Domain, code: code, userInfo: userInfo)
        }
    }
}
