
import Alamofire

public protocol NetworkDataRequest: NetworkRequest {

}

extension NetworkDataRequest {
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
