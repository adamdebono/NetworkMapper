
/// The error type returned by NetworkMapper
///
/// - invalidResponse:  The response JSON was not in a format that could be
///                     decoded
public enum ResponseError: Error {
    case invalidResponse
}
