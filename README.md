# NetworkMapper

A framework to map JSON responses to swift objects, based on
[Alamofire](https://github.com/Alamofire/Alamofire) and
[Unbox](https://github.com/JohnSundell/Unbox).

## Installation

### Cocoapods
```ruby
pod 'NetworkMapper', '~> 0.1.2'
```

## Usage
NetworkMapper makes use of protocols to implement functionality. The protocols
only require you to define instance variables for the method, url and parameters
of the request.

### Basic Request
You can make basic requests that don't map the response by conforming to
`NetworkRequest`. You can use `responseJSON` or `responseData` to retrieve the
response from the server.

```swift
struct ExampleRequest: NetworkRequest {
  let method: HTTPMethod = .get
  let url: URL = URL(string: "https://example.org/example/user")
  let parameters: [String:Any]? = nil
}

ExampleRequest().responseJSON { response in
  switch response.result {
  case .failure(let error):
    // process error
  case .success(let json):
    // process response
  }
}
```

### Mapped Request
A mapped request is slightly more complicated. Mapped requests require you to
create an object that conforms to `NetworkObjectRequest` and
`NetworkObjectResponse`.

The response protocol requires you to conform to the `Unboxable` protocol, see
it's [documentation](https://github.com/JohnSundell/Unbox#unbox) for more
information. The response object is treated as the root object of the JSON
response. Currently arrays as a root object is not supported.

The request protocol adds on to `NetworkRequest` by adding an associatedtype,
which specifies the type of response object. On completion of the request, the
JSON object will be mapped to the response object. There is one other function,
`responseDecoded` which can be optionally implemented, the default
implementation of which does nothing.

```swift
struct ExampleObjectRequest: NetworkObjectRequest {
  typealias ResponseType = ExampleObjectResponse

  let method: HTTPMethod = .get
  let url: URL = URL(string: "https://example.org/example/users")
  let parameters: [String:Any]? = nil
}

struct ExampleObjectResponse: NetworkObjectResponse {
  let users: [User]
  let pageNumber: Int

  init(unboxer: Unboxable) throws {
    self.users = try unboxer.unbox(key: "users")
    self.pageNumber = try unboxer.unbox(keyPath: "pagination.page_number")
  }
}

struct User: Unboxable {
  let name: String
  let age: Int

  init(unboxer: Unboxable) throws {
    self.name = try unboxer.unbox(key: "name")
    self.name = try unboxer.unbox(key: "age")
  }
}

ExampleObjectRequest().responseObject { response in
  switch response.result {
  case .failure(let error):
    // process error
  case .success(let object):
    // process response
  }
}
```
