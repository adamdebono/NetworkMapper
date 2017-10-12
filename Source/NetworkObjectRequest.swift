
import Alamofire
import Foundation

/// A protocol to define network requests that map directly to response objects
public protocol NetworkObjectRequest: NetworkDataRequest {
    /// The type of the response object
    associatedtype ResponseType: NetworkObjectResponse
}
/// A protocol to define network response objects
public protocol NetworkObjectResponse: Decodable {

}

public extension NetworkObjectRequest {
    /// Performs a network request based on the attributes of this instance, and
    /// retrieves the response object
    ///
    /// - parameter completionHandler:  A callback which is run on the
    ///                                 completion of the request
    ///
    /// - returns: The request that was sent
    @discardableResult
    public func responseObject(completionHandler: @escaping ((DataResponse<ResponseType>) -> Void)) -> DataRequest {
        return self.responseData { response in
            self.processObjectResponse(response: response, completionHandler: completionHandler)
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
    public func uploadResponseObject(_ data: Data, completionHandler: @escaping ((DataResponse<ResponseType>) -> Void)) -> UploadRequest {
        return self.uploadResponseData(data, completionHandler: { response in
            self.processObjectResponse(response: response, completionHandler: completionHandler)
        })
    }
    
    /// Performs an upload request based on the attributes of this instance, and
    /// retrieves the response object
    ///
    /// - parameter multipartFormData:  The closure used to append body parts to
    ///                                 the `MultipartFormData`.
    /// - parameter completionHandler:  A callback which is run on completion of
    ///                                 the request
    public func uploadResponseObject(multipartFormData: @escaping ((MultipartFormData) -> Void), completionHandler: @escaping ((DataResponse<ResponseType>) -> Void)) {
        self.uploadResponseData(multipartFormData: multipartFormData, completionHandler: { response in
            self.processObjectResponse(response: response, completionHandler: completionHandler)
        })
    }
    
    /// Processes an object response from the server
    ///
    /// This can be overridden to provide custom processing. The default
    /// implementation will attempt to unbox the object response from the root
    /// json object of the response.
    ///
    /// - parameter response:           The response to process
    /// - parameter completionHandler:  A callback which is run once processing
    ///                                 is complete
    public func processObjectResponse(response: DataResponse<Data>, completionHandler: @escaping ((DataResponse<ResponseType>) -> Void)) {
        switch response.result {
        case .failure(let error):
            self.complete(error: error, response: response, completionHandler: completionHandler)
        case .success(let value):
            do {
                let object = try JSONDecoder().decode(ResponseType.self, from: value)
                self.complete(object: object, response: response, completionHandler: completionHandler)
            } catch let error {
                self.complete(error: error, response: response, completionHandler: completionHandler)
            }
        }
    }
}
