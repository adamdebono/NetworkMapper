
import Alamofire
import Foundation
import Unbox

public protocol NetworkObjectRequest: NetworkRequest {
    associatedtype ResponseType: NetworkObjectResponse
    
    func responseDecoded(_ response: ResponseType)
}
public protocol NetworkObjectResponse: Unboxable {
  
}

public extension NetworkObjectRequest {
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
    
    public func responseDecoded(_ response: ResponseType) {}
}
