
import Alamofire
import AlamofireImage

#if os(watchOS)
import UIKit
#endif

public protocol NetworkImageRequest: NetworkRequest {
}

extension NetworkImageRequest {

    #if os(iOS) || os(tvOS) || os(watchOS)

    /// Performs a network request based on the attributes of this instance, and
    /// retrieves the response image
    ///
    /// - parameter imageScale:             The scale factor to use when
    ///                                     interpreting the response image
    /// - parameter inflateResponseImage:   Whether to automatically inflate
    ///                                     response image data from compressed
    ///                                     formats
    /// - parameter completionHandler:      A callback which is run on
    ///                                     completion of the request
    ///
    /// - returns: The request that was sent
    @discardableResult
    public func responseImage(imageScale: CGFloat = DataRequest.imageScale, inflateResponseImage: Bool = true, completionHandler: @escaping ((DataResponse<Image>) -> Void)) -> DataRequest {
        return self.sessionManager
            .request(self)
            .responseImage(imageScale: imageScale, inflateResponseImage: inflateResponseImage, queue: nil, completionHandler: completionHandler)
    }

    /// Performs a network request based on the attributes of this instance, and
    /// periodically loads the response image as data is loaded.
    ///
    /// - parameter imageScale:             The scale factor to use when
    ///                                     interpreting the response image
    /// - parameter inflateResponseImage:   Whether to automatically inflate
    ///                                     response image data from compressed
    ///                                     formats
    /// - parameter completionHandler:      A callback which is run when the
    ///                                     request has a new image
    ///
    /// - returns: The request that was sent
    @discardableResult
    public func streamImage(imageScale: CGFloat = DataRequest.imageScale, inflateResponseImage: Bool = true, completionHandler: @escaping ((Image) -> Void)) -> DataRequest {
        return self.sessionManager
            .request(self)
            .streamImage(imageScale: imageScale, inflateResponseImage: inflateResponseImage, completionHandler: completionHandler)
    }

    #elseif os(macOS)

    /// Performs a network request based on the attributes of this instance, and
    /// retrieves the response image
    ///
    /// - parameter completionHandler:      A callback which is run on
    ///                                     completion of the request
    ///
    /// - returns: The request that was sent
    @discardableResult
    public func responseImage(completionHandler: @escaping ((DataResponse<Image>) -> Void)) -> DataRequest {
    return self.sessionManager
        .request(self)
        .responseImage(queue: nil, completionHandler: completionHandler)
    }

    /// Performs a network request based on the attributes of this instance, and
    /// periodically loads the response image as data is loaded.
    ///
    /// - parameter imageScale:             The scale factor to use when
    ///                                     interpreting the response image
    /// - parameter inflateResponseImage:   Whether to automatically inflate
    ///                                     response image data from compressed
    ///                                     formats
    /// - parameter completionHandler:      A callback which is run when the
    ///                                     request has a new image
    ///
    /// - returns: The request that was sent
    @discardableResult
    public func streamImage(completionHandler: @escaping ((Image) -> Void)) -> DataRequest {
    return self.sessionManager
        .request(self)
        .streamImage(completionHandler: completionHandler)
    }

    #endif
}
