MoyaX Guides
====

*注：MoyaX 的大部分公开的数据结构和方法均有代码文档，可以在 XCode 中快速查阅，另有[使用技巧](HowTo_zh.md)。*

MoyaX 由三部分组成：

- Target：用于定义服务器端 API
- Provider：可配置、可复用，用于利用 Target 请求服务器端 API
- Backend：由 Provider 使用，用于处理请求

## Target

Target 协议用于描述一个服务器端 API，其包含一下字段：

- `baseURL`：必填，用于表达基本地址，如 `https://api.mysite.com/v1`, 如果你的应用包含了多个服务器环境（如生产环境、测试环境、开发环境）可以通过修改这个字段来控制。
- `path`：必填，用于表达 API 的路径
- `method`：可选，请求方式，默认为 `.GET`
- `headerFields`：可选，自定义 HTTP 请求头，默认为空
- `parameters`：可选，请求数据，默认为空
- `parameterEncoding`：可选，请求数据的编码方式，默认使用表单提交（`.URL`)，如果涉及文件上传，使用 `.MultipartFormData`，另外还支持 `.JSON`

### 使用方式

作为协议，`class`、`struct`、`enum` 都可以用来实现 `Target`，推荐 API 数量少且简单的时候使用 `enum`，复杂的场景使用 `struct`

#### 基于结构体（或类）的 Target

```swift
// 这个结构体封装了 Github 的返回指定用户信息的 API
struct GithubShowUser: Target {
  // 要请求的用户的用户名
  let name: String

  // 构造函数
  init(name: String) {
    self.name = name
  }

  // 必须实现，API 的地址
  var baseURL: NSURL {
    return NSURL(string: "https://api.github.com")!
  }

  // 必须实现，API 的路径
  var path: String {
    return "/users/\(name)"
  }

  // 可以省略，API 的请求方式，默认为 .get
  var method: HTTPMethod {
    return .get
  }

  // 可以省略，额外的 HTTP 请求头信息，默认为空
  var headerFields: [String: String] {
    return [:]
  }

  // 可以省略，HTTP 请求的表单数据，默认为空
  var parameters: [String: AnyObject] {
     return [:]
  }

  // 可以省略，HTTP 请求的表单数据的编码方式，默认为 .url，即以 HTTP 表单方式提交 parameters
  var parameterEncoding: ParameterEncoding {
     return .url
  }
}
```

#### 基于枚举的 Target

```swift
// 使用枚举声明 API 列表
enum MyService {
  case zen
  case showUser(id: Int)
  case createUser(firstName: String, lastName: String)
}

// 实现 Target 协议
extension MyService: Target {
  // 必须实现，API 的地址
  var baseURL: NSURL {
    return NSURL(string: "https://api.myservice.com")!
  }
    
  // 必须实现，API 的路径
  var path: String {
    switch self {
    case .Zen:
      return "/zen"
    case .ShowUser(let id):
      return "/users/\(id)"
    case .CreateUser(_, _):
      return "/users"
    }
  }
    
  // 可以省略，API 的请求方式，默认为 .get
  var method: HTTPMethod {
    switch self {
    case .zen, .showUser:
      return .get
    case .createUser:
      return .post
    }
  }
    
  // 可以省略，额外的 HTTP 请求头信息，默认为空
  var headerFields: [String: String] {
    return [:]
  }  
  
  // 可以省略，HTTP 请求的表单数据，默认为空
  var parameters: [String: AnyObject] {
    switch self {
    case .zen, .showUser:
      return [:]
    case .createUser(let firstName, let lastName):
      return ["first_name": firstName, "last_name": lastName]
    }
  }

  // 可以省略，HTTP 请求的表单数据的编码方式，默认为 .url，即以 HTTP 表单方式提交 parameters
  var parameterEncoding: ParameterEncoding {
     return .url
  }
}
```

## Provider

Provider 通过传入 Target 来请求服务器端 API，可复用，你可以将其作为 ViewController 的属性，也可以包装成全局单例。根据需要你也可以进行二次封装。

Provider 提供了钩子、中间件机制，为运行时动态定制请求提供了便利。

MoyaX 中提供了通用的 `MoyaXProvider` 和为使用枚举声明 Target 提供便利的 `MoyaXGenericProvider`，你可以根据自己的需要将这两个作为基类来继承，比如包装成 `RxMoyaXProvider`。

最基本的使用方法：

```swift
// 初始化 MoyaXProvider
let provider = MoyaXProvider()

// 发出请求
provider.request(GithubShowUser(name: "jasl")) { response in
  // 在回调中处理响应，response 为枚举
  switch response {

  // 服务器有返回结果，注意服务器返回 4xx、5xx 也走这里
  case let .response(response):
    // 服务器端返回的数据，为 NSData
    let data = response.data
    // 服务器端返回的状态码
    let statusCode = response.statusCode
    // 在这里处理响应

  // 网络原因（连通性或者超时）服务器没有返回结果、请求被取消或者其他异常
  case let .incomplete(error):
    // 在这里处理请求失败，error 是一个枚举
  }
}
```

注意在请求过程中 Provider 的实例必须被 ViewController 或者某个变量持有，以下用法是错误的，会导致未知行为发生：

```swift
func requestShowUser(name: String) {
  let provider = MoyaXProvider()
  provider.request(GithubShowUser(name: name)) { response
    // 处理响应，这里省略
  }
}

// 函数调用后 provider 变量会被回收，而请求还未返回
// 这样调用会产生不期望的结果
requestShowUser("jasl")
```

### Provider#request 方法的业务流程

执行流程如下，你可以根据需要在钩子点插入代码

1. `Target` 的 `endpoint` 计算属性
2. `Provider` 的 `prepareForEndpoint(endpoint)` 闭包
3. 中间件的 `willSendRequest(target, endpoint)` 方法
4. 若 `endpoint.willPerform` 属性的真，调用 `Backend#request(endpoint)` 方法处理请求
5. 中间件的 `didReceiveResponse(target, response)` 方法
6. 处理响应的回调闭包

### 中间件

中间件适合处理诸如记录日志、插入统计信息等工作。

声明一个中间件非常简单，只需实现 `Middleware` 协议即可：

```swift
// 一个简单的 logger
class LoggerMiddleware: Middleware {
  // 这个方法会在请求发送前被调用
  func willSendRequest(target: Target, endpoint: Endpoint) {
    logger.info("Sending request: \(endpoint.URL.absoluteString)")
  }
  
  // 这个方法会在处理响应的回调闭包前被调用
  func didReceiveResponse(target: Target, response: Result<Response, Error>) {
    switch response {
    case let .response(response):
      logger.info("Received response(\(response.statusCode ?? 0)) from \(response.response!.URL?.absoluteString ?? String()).")
    case .incomplete(_):
      logger.error("Got error")
    }
  }
}

// 使用
let provider = provider(middlewares: [LoggerMiddleware()])
```

## Backend

Backend 负责真正处理请求，MoyaX 自带两种后端：

- `AlamofireBackend`：默认，使用 Alamofire 发送和处理请求
- `StubBackend`：用于测试或者原型演示时返回模拟请求

### 指定 Backend

在初始化 Provider 时，你可以指定 Backend：

```swift
let provider = Provider(backend: StubBackend())
```

默认为 `AlamofireBackend`

你也可以在请求前临时替换一个 Backend：

```swift
let backend = AlamofireBackend()
provider.request(GithubShowUser(), withCustomBackend: backend) { response in
  // 处理响应
}
```

### `AlamofireBackend`

`AlamofireBackend` 为默认启用的 Backend，但你也可以手动初始化他并指定给 Provider 来获取额外的定制可能，如：

- `manager`：指定 Alamofire 的 `Manager`，推荐设置 `manager.startRequestsImmediately = false`
- `willPerformRequest: (Endpoint, Alamofire.Request) -> ()`：钩子闭包，在请求被发送前执行，这里暴露了 Alamofire 的 `Request` 对象
- `didReceiveResponse: (Endpoint, Alamofire.Response<NSData, NSError>) -> ()`：钩子闭包，在接受到响应、异常后执行，这里暴露了 Alamofire 的 `Response` 对象
- `multipartFormDataEncodingMemoryThreshold`：用于上传时的内存阈值

#### Multipart 上传

当 `Target#parameterEncoding` 为 `.MultipartFormData` 时，会使用 Alamofire 的 

```swift
public func upload(
        method: Method,
        _ URLString: URLStringConvertible,
        headers: [String: String]? = nil,
        multipartFormData: MultipartFormData -> Void,
        encodingMemoryThreshold: UInt64,
        encodingCompletion: (MultipartFormDataEncodingResult -> Void)?)
```

方法来执行上传，`AlamofireBackend` 做了一些处理使得上传和其他请求方式统一，流程如下：

- 创建用于取消请求的 `CancellableToken`
- 在 `encodingCompletion` 回调闭包中持有这个 `CancellableToken` 的引用
- 执行 `encodingCompletion` 时检查 `CancellableToken` 是否已被取消，是则流程终止
- 构建 `Request`，将引用设置给 `CancellableToken`
- 执行请求

*注：`CancellableToken` 仅暴露 `cancel()` 方法，其内部成员均由 MoyaX 操作，来避免 side-effect

### `StubBackend`

`StubBackend` 方便在开发过程中提供 Stub 请求的功能，可以替代如 [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs) 等 Stub 网络请求库

注意，Stub 的是 Target，而不是根据 URL 和 Method。

#### 默认响应

为了能够让 Target 提供默认的响应数据，需要再实现 `TargetWithSample` 协议：

```swift
struct GithubZen: Target {
  // 实现 Target 协议，这里省略
}

extension GithubZen: TargetWithSample {
  var sampleResponse: StubResponse {   	 
    return .networkResponse(200,
                            "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!)
  }  
}
```

#### 基本使用

令 Target 实现 `TargetWithSample` 协议后，只需要将 Backend 指定为 `StubBackend` 即可：

```swift
// 初始化 MoyaXProvider
let provider = MoyaXProvider(backend: StubBackend())

// 发出请求
provider.request(GithubZen()) { response in
  // 在回调中处理响应，response 为枚举
  switch response {

  // 服务器有返回结果，注意服务器返回 4xx、5xx 也走这里
  // 因为是 Stub 的，这里的值和在 sampleResponse 设置的一样
  case let .response(response):
    // 服务器端返回的数据，为 NSData
    let data = response.data
    // 服务器端返回的状态码
    let statusCode = response.statusCode
    // 在这里处理响应

  // 网络原因（连通性或者超时）服务器没有返回结果、请求被取消或者其他异常
  case let .incomplete(error):
    // 在这里处理请求失败，error 是一个枚举
  }
}
```

可见，除开指定 Backend 到 `StubBackend` 以外，其他代码不需要做任何改动。

#### 默认设置

在初始化时，你也可以定制默认的行为和默认响应：

- `defaultBehavior`：默认为 `.immediate`，即立即响应，你还可以设置 `.delayed(NSTimeInterval)` 来延迟一段时间响应（默认真实环境）
- `defaultResponse`：默认为 `.noStubError`，当没有实现 `TargetWithSample` 时，并且也没有在 `StubBackend` stub Target时，程序将崩溃退出

#### 在 `StubBackend` 端 stub Target

你也可以在 `StubBackend` 这端 stub 一个 Target，你可以定制：

- `behavior`：响应的行为，默认为立即响应 `.immediate`，也可以设置 `.delayed(NSTimeInterval)` 来延迟一段时间响应（默认真实环境）
- `conditionalResponse`：签名为 `(endpoint: Endpoint, target: Target?) -> StubResponse` 的闭包，允许你在运行时根据请求来定制响应 

```swift
let target = GithubZen()

let stubBackend = StubBackend()
stubBackend.stubTarget(target, behavior: .Delayed(2), conditionalResponse: { endpoint, target in
  // 这里我们设定随机数为偶数返回结果，为奇数抛出网络异常
  if arc4random() % 2 == 0 {
    return .networkResponse(200,
                            "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!)
  } else {
  	 return .networkError(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil))
  }
}

// 正常的使用 MoyaX
let provider = MoyaXProvider(backend: stubBackend)
provider.request(target) { response
// 在回调中处理响应，response 为枚举
  switch response {

  // 上文取随机数为偶数的时候执行这里
  case let .response(response):
    // 服务器端返回的数据，为 NSData
    let data = response.data
    // 服务器端返回的状态码
    let statusCode = response.statusCode
    // 在这里处理响应

  // 上文取随机数为奇数的时候执行这里
  case let .incomplete(error):
    // 在这里处理请求失败，这里 error 的值为 .BackendResponse
  }
}
```

当然你也可以删除掉刚才的 stub：

```swift
// 删除指定的 stub
stubBackend.removeStubTarget(target)

// 清空
stubBackend.removeAllStubs()
```
