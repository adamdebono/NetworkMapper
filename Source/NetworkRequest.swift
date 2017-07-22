
import Alamofire
import Foundation

/// Contains basic information which is used to create a `URLRequest`
public struct RequestDetails: URLRequestConvertible {
  
    /// The HTTP method of the request
    public let method: HTTPMethod
    /// The url of the request
    public let url: URL
    /// Any parameters (or nil) for the request
    ///
    /// Parameters are encoded and added to the request based on the method of
    /// the request
    public let parameters: [String: Any]?
    /// Any headers (or nil) for the request
    public var headers: HTTPHeaders?
    
    public init(method: HTTPMethod, url: URL, parameters: [String: Any]?, headers: HTTPHeaders?) {
        self.method = method
        self.url = url
        self.parameters = parameters
        self.headers = headers
    }
    
    public func asURLRequest() throws -> URLRequest {
        let request = try URLRequest(url: self.url, method: self.method, headers: self.headers)
        
        return try URLEncoding.methodDependent.encode(request, with: self.parameters)
    }
}

/// A basic protocol to define network requests
public protocol NetworkRequest: URLRequestConvertible {
    /// The session manager to make the request on
    var sessionManager: Alamofire.SessionManager { get }

    /// The HTTP method of the request
    var method: HTTPMethod { get }
    /// The url of the request
    var url: URL { get }
    /// Any parameters (or nil) for the request
    ///
    /// Parameters are encoded and added to the request based on the method of
    /// the request
    var parameters: [String: Any]? { get }
    /// Any headers (or nil) for the request
    var headers: HTTPHeaders? { get }

    /// The validation block to run which validates requests.
    ///
    /// If this is not provided, default validation is used
    var validation: DataRequest.Validation? { get }

    /// A callback function which is called after the request succeeds,
    /// immediately before the callback
    ///
    /// The default implementation of this funciton does nothing.
    ///
    /// - parameter response:   The decoded response in the format requested
    func onSuccess<T>(_ response: T, request: URLRequest?) -> Void
    /// A callback function which is called after the request fails, immediately
    /// before the callback
    ///
    /// The default implementation of this funciton does nothing.
    ///
    /// - parameter error:  The error that caused the failure
    func onError(_ error: Error, request: URLRequest?) -> Void
}
public extension NetworkRequest {
    /// Creates a `RequestDetails` object based on the attributes of the
    /// instance
    public func getRequestDetails() -> RequestDetails {
        return RequestDetails(
            method: self.method,
            url: self.url,
            parameters: self.parameters,
            headers: self.headers
        )
    }
    
    public func asURLRequest() throws -> URLRequest {
        return try self.getRequestDetails().asURLRequest()
    }
    
    /// Performs the completionHandler when an error occurs during the response
    /// handler
    ///
    /// This is a convenience function to map the response type to the expected
    /// completion type
    ///
    /// - parameter error:              The error that occurred
    /// - parameter response:           The response from the Alamofire
    /// - parameter completionHandler:  The completion handler to run
    public func complete<R, T>(error: Error, response: DataResponse<R>?, completionHandler: (DataResponse<T>) -> Void) {
        self.onError(error, request: response?.request)

        let result = Result<T>.failure(error)
        let errorResponse = DataResponse(request: response?.request, response: response?.response, data: response?.data, result: result)
        completionHandler(errorResponse)
    }
    /// Performs the completionHandler after a response is successfuly handled
    ///
    /// This is a convenience function to map the response type to the expected
    /// completion type
    ///
    /// - parameter object:             The decoded response object
    /// - parameter response:           The response from Alamofire
    /// - parameter completionHandler:  The completion handler to run
    public func complete<R, T>(object: T, response: DataResponse<R>, completionHandler: (DataResponse<T>) -> Void) {
        self.onSuccess(object, request: response.request)

        let result = Result<T>.success(object)
        let successResponse = DataResponse(request: response.request, response: response.response, data: response.data, result: result)
        completionHandler(successResponse)
    }

    public func onSuccess<T>(_ response: T, request: URLRequest?) {}
    public func onError(_ error: Error, request: URLRequest?) {}

    // MARK: Data
    
    /// Performs a network request based on the attributes of this instance, and
    /// retrieves the response data
    ///
    /// - parameter completionHandler:  A callback which is run on completion of
    ///                                 the request
    ///
    /// - returns: The request that was sent
    @discardableResult
    public func responseData(completionHandler: @escaping ((DataResponse<Data>) -> Void)) -> DataRequest {
        return self.sessionManager
            .request(self)
            .validate(self.validation)
            .responseData(completionHandler: { response in
                switch response.result {
                case .failure(let error):
                    if let error = error as? URLError {
                        if error.code == URLError.cancelled {
                            return
                        }
                    }
                default:
                    break
                }
                
                completionHandler(response)
            })
    }
    
    /// Performs an upload request based on the attributes of this instance, and
    /// retrieves the response data
    ///
    /// - parameter data:               The data to upload
    /// - parameter completionHandler:  A callback which is run on completion of
    ///                                 the request
    ///
    /// - returns: The request that was sent
    @discardableResult
    public func uploadResponseData(_ data: Data, completionHandler: @escaping ((DataResponse<Data>) -> Void)) -> UploadRequest {
        return self.sessionManager
            .upload(data, with: self)
            .validate(self.validation)
            .responseData(completionHandler: { (response) in
                switch response.result {
                case .failure(let error):
                    if let error = error as? URLError {
                        if error.code == URLError.cancelled {
                            return
                        }
                    }
                default:
                    break
                }
                
                completionHandler(response)
            })
    }

    /// Performs an upload request based on the attributes of this instance, and
    /// retrieves the resonse data
    ///
    /// - parameter multipartFormData: The clouse used to append body parts to
    ///                                the `MultipartFormData`
    /// - parameter completionHandler: A callback which is run on completion of
    ///                                the request
    public func uploadResponseData(multipartFormData: @escaping ((MultipartFormData) -> Void), completionHandler: @escaping ((DataResponse<Data>) -> Void)) {
        self.sessionManager
            .upload(multipartFormData: multipartFormData, with: self, encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseData(completionHandler: completionHandler)
                case .failure(let error):
                    let response: DataResponse<Data>? = nil
                    self.complete(error: error, response: response, completionHandler: completionHandler)
                }
            })
    }
    
    // MARK: JSON
    
    /// Performs a network request based on the attributes of this instance, and
    /// retrieves the response json
    ///
    /// - parameter completionHandler:  A callback which is run on completion of
    ///                                 the request
    ///
    /// - returns: The request that was sent
    @discardableResult
    public func responseJSON(completionHandler: @escaping ((DataResponse<Any>) -> Void)) -> DataRequest {
        return self.sessionManager
            .request(self)
            .validate(self.validation)
            .responseJSON { response in
                self.processJSONResponse(response: response, completionHandler: completionHandler)
            }
    }
    
    /// Performs an upload request based on the attributes of this instance, and
    /// retrieves the response json
    ///
    /// - parameter data:               The data to upload
    /// - parameter completionHandler:  A callback which is run on completion of
    ///                                 the request
    ///
    /// - returns: The request that was sent
    @discardableResult
    public func uploadResponseJSON(_ data: Data, completionHandler: @escaping ((DataResponse<Any>) -> Void)) -> UploadRequest {
        return self.sessionManager
            .upload(data, with: self)
            .validate(self.validation)
            .responseJSON { response in
                self.processJSONResponse(response: response, completionHandler: completionHandler)
            }
    }
    
    /// Performs an upload request based on the attributes of this instance, and
    /// retrieves the response json
    ///
    /// - parameter multipartFormData:  The closure used to append body parts to
    ///                                 the `MultipartFormData`.
    /// - parameter completionHandler:  A callback which is run on completion of
    ///                                 the request
    public func uploadResponseJSON(multipartFormData: @escaping ((MultipartFormData) -> Void), completionHandler: @escaping ((DataResponse<Any>) -> Void)) {
        self.sessionManager.upload(multipartFormData: multipartFormData, with: self, encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON(completionHandler: completionHandler)
            case .failure(let error):
                let response: DataResponse<Any>? = nil
                self.complete(error: error, response: response, completionHandler: completionHandler)
            }
        })
    }
    
    /// Processes a JSON response from the server
    ///
    /// This can be overridden to provide custom processing. The default
    /// implementation only checks for request cancellation.
    ///
    /// - parameter response:           The response to process
    /// - parameter completionHandler:  A callback which is run once processing
    ///                                 is complete
    public func processJSONResponse(response: DataResponse<Any>, completionHandler: @escaping ((DataResponse<Any>) -> Void)) {
        switch response.result {
        case .failure(let error):
            if let error = error as? URLError {
                if error.code == URLError.cancelled {
                    return
                }
            }
        default:
            break
        }

        completionHandler(response)
    }
}

extension DataRequest {
    @discardableResult
    public func validate(_ optionalValidation: Validation?) -> Self {
        if let validation = optionalValidation {
            return self.validate(validation)
        } else {
            return self.validate()
        }
    }
}
