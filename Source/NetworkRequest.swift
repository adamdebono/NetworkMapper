
import Alamofire
import Foundation

public struct RequestDetails: URLRequestConvertible {
    public let method: HTTPMethod
    public let url: URL
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

public protocol NetworkRequest: URLRequestConvertible {
    var method: HTTPMethod { get }
    var url: URL { get }
    var parameters: [String: Any]? { get }
}
public extension NetworkRequest {
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
    
    public func complete<R, T>(error: Error, response: DataResponse<R>?, completionHandler: (DataResponse<T>) -> Void) {
        let result = Result<T>.failure(error)
        let errorResponse = DataResponse(request: response?.request, response: response?.response, data: response?.data, result: result)
        completionHandler(errorResponse)
    }
    public func complete<R, T>(object: T, response: DataResponse<R>, completionHandler: (DataResponse<T>) -> Void) {
        let result = Result<T>.success(object)
        let successResponse = DataResponse(request: response.request, response: response.response, data: response.data, result: result)
        completionHandler(successResponse)
    }
    
    // MARK: Data
    
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
    
    @discardableResult
    public func responseJSON(completionHandler: @escaping ((DataResponse<Any>) -> Void)) -> DataRequest {
        return Alamofire.request(self).responseJSON { response in
            self.processJSONResponse(response: response, completionHandler: completionHandler)
        }
    }
    
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
