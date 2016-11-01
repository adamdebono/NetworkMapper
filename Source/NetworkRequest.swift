
import Alamofire
import Foundation
import Unbox

public struct RequestDetails {
    public let method: HTTPMethod
    public let url: URL
    public let parameters: [String: Any]?
    
    public init(method: HTTPMethod, url: URL, parameters: [String: Any]? = nil) {
        self.method = method
        self.url = url
        self.parameters = parameters
    }
}

public protocol NetworkRequest: URLRequestConvertible {
    associatedtype ResponseType: Unboxable
    
    var method: HTTPMethod { get }
    var url: URL { get }
    var parameters: [String: Any]? { get }
    
    func responseDecoded(_ response: ResponseType)
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
        let requestDetails = self.getRequestDetails()
        var request = URLRequest(url: requestDetails.url)
        request.httpMethod = requestDetails.method.rawValue
        
        return try URLEncoding.methodDependent.encode(request, with: requestDetails.parameters)
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
    
    @discardableResult
    public func responseObject(completionHandler: @escaping ((DataResponse<ResponseType>) -> Void)) -> DataRequest {
        return self.responseJSON { response in
            self.processObjectResponse(response: response, completionHandler: completionHandler)
        }
    }
    public func processObjectResponse(response: DataResponse<Any>, completionHandler: @escaping ((DataResponse<ResponseType>) -> Void)) {
        switch response.result {
        case .failure(let error):
            self.complete(error: error, response: response, completionHandler: completionHandler)
        case .success(let value):
            guard let value = value as? [String: Any] else {
                let error = ResponseError.invalidResponse
                self.complete(error: error, response: response, completionHandler: completionHandler)
                return
            }
            
            do {
                let object: ResponseType = try unbox(dictionary: value)
                self.responseDecoded(object)
                self.complete(object: object, response: response, completionHandler: completionHandler)
            } catch let unboxError as UnboxError {
                self.complete(error: unboxError, response: response, completionHandler: completionHandler)
            } catch {
                let error = ResponseError.invalidResponse
                self.complete(error: error, response: response, completionHandler: completionHandler)
            }
        }
    }
}
