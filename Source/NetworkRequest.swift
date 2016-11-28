
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
    
    public init(method: HTTPMethod, url: URL, parameters: [String: Any]? = nil) {
        self.method = method
        self.url = url
        self.parameters = parameters
    }
    
    public func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: self.url)
        request.httpMethod = self.method.rawValue
        
        return try URLEncoding.methodDependent.encode(request, with: self.parameters)
    }
}

/// A basic protocol to define network requests
public protocol NetworkRequest: URLRequestConvertible {
    /// The HTTP method of the request
    var method: HTTPMethod { get }
    /// The url of the request
    var url: URL { get }
    /// Any parameters (or nil) for the request
    ///
    /// Parameters are encoded and added to the request based on the method of
    /// the request
    var parameters: [String: Any]? { get }
}
public extension NetworkRequest {
    /// Creates a `RequestDetails` object based on the attributes of the
    /// instance
    public func getRequestDetails() -> RequestDetails {
        return RequestDetails(
            method: self.method,
            url: self.url,
            parameters: self.parameters
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
        let result = Result<T>.success(object)
        let successResponse = DataResponse(request: response.request, response: response.response, data: response.data, result: result)
        completionHandler(successResponse)
    }
    
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
        return Alamofire.request(self).responseData(completionHandler: { response in
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
        return Alamofire.request(self).responseJSON { response in
            self.processJSONResponse(response: response, completionHandler: completionHandler)
        }
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
