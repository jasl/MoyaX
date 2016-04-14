MoyaX
====

MoyaX 是一款网络抽象层的封装库，基于 [Moya 6.1.3](https://github.com/Moya/Moya) 进行了大规模的重构，它目前主要使用在我的 [iOS 学习项目](https://github.com/jasl/RubyChinaAPP) 中，目前测试基本覆盖，可以证明项目是可用的。

MoyaX 的目标是提供一个的 Moya 改进版本，并且功能上覆盖 Moya 的使用场景。

MoyaX 虽然已经和 Moya 有极大的不同，但我仍在跟随原始项目的变动，学习、吸取经验和好的部分。

**非常、特别、强烈希望能够对设计、实现以及功能上提供反馈。**

## 基本使用

### 声明 API 端点

实现`Target`协议即可，其中包含了描述一个 API端点的必要信息，详情请见 [定义](https://github.com/jasl/MoyaX/blob/master/Source/MoyaX.swift#L4-L36)

其中`baseURL`和`path`为必须实现，其余为可选。

#### 枚举式

可以沿用 Moya 的方式，例：

```swift
enum GitHub {
    case Zen
    case UserProfile(String)
    case UserRepositories(String)
}

extension GitHub: Target {
    // Required
    
    var baseURL: NSURL { 
        return NSURL(string: "https://api.github.com")!
    }
    
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        case .UserRepositories(let name):
            return "/users/\(name.URLEscapedString)/repos"
        }
    }
    
    // Optional
    
    // Default is .GET
    var method: HTTPMethod {
        return .GET
    }
    
    // Default is empty dictionary
    var parameters: [String: AnyObject] {
        switch self {
        case .UserRepositories(_):
            return ["sort": "pushed"]
        default:
            return [:]
        }
    }
    
    // Default is .Form
    var parameterEncoding: ParameterEncoding {
        return .Form
    }
    
    // Default is empty dictionary
    var headerFields: [String: String] {
        return [:] 
    }
```

#### 结构体、类式

```swift
struct ListingTopics: Target {
    enum TypeFieldValue: String {
        case LastActived = "last_actived"
        case Recent = "recent"
        case NoReply = "no_reply"
        case Popular = "popular"
        case Excellent = "excellent"
    }

    var type: TypeFieldValue?
    var nodeId: String?
    var offset: Int
    var limit: Int

    init(type: TypeFieldValue? = nil, nodeId: String? = nil, offset: Int = 0, limit: Int = 20) {
        self.type = type
        self.nodeId = nodeId
        self.offset = offset
        self.limit = limit
    }

    var baseURL: NSURL { 
        return NSURL(string: "https://ruby-china.org/api/v3/")!
    }
    
    var path: String {
    	  return "topics"
    }
    
    var parameters: [String: AnyObject] {
        var parameters = [String: AnyObject]()

        if let type = self.type {
            parameters["type"] = type.rawValue
        }
        if let nodeId = self.nodeId {
            parameters["nodeId"] = nodeId
        }

        parameters["limit"] = self.limit
        parameters["offset"] = self.offset

        return parameters
    }
}
```

### 创建`Provider`实例

最基本的使用方式，默认使用`AlamofireBackend`后端

```swift
// Common version
let provider = MoyaXProvider()    

// Generic version
let provider = MoyaXGenericProvider<GitHub>()                          
```

### 发送请求

以泛型`Provider`为例，和 Moya 的使用方式完全相同

```swift
provider.request(.Zen) { result in
    // `result` is either .Response(response) or .Incomplete(error)
}
```

## 高级使用

### Target

你可以通过覆写`Target`的`endpoint`计算属性在运行时自定义`Endpoint`的构造过程，比如根据应用的状态附加一些内容，这在使用枚举方式声明的时候非常有用

```swift
var endpoint: Endpoint {
    var endpoint = Endpoint(URL: self.fullURL, method: self.method, parameters: self.parameters, parameterEncoding: self.parameterEncoding, headerFields: self.headerFields)
    endpoint.headerFields["X-Xapp-Token"] = XAppToken().token ?? ""
    return endpoint
}
```

### Provider

#### ReactiveCocoa 和 RxSwift

ReactiveCocoa 和 RxSwift 的支持将被移除 MoyaX，以独立库的方式存在。

#### 构造函数的可选参数

`Provider`的构造函数可以接受如下几个可选参数：

- `backend: Backend`：指定后端
- `middlewares: [Middleware]`：插件，自带网络状态插件，[参见源码](https://github.com/jasl/MoyaX/tree/master/Source/Middlewares)
- `prepareForEndpoint: Endpoint -> ()` 钩子，用于公共的对`Endpoint`修饰，例如附加 Token

#### `request`方法

可以传入`withCustomBackend: BackendType`来临时性指定一个后端来执行请求。

### Backend

#### `AlamofireBackend`

##### 构造函数的可选参数

- `manager: Manager` 指定 Alamofire 的 Manager 实例
- `willPerformRequest: (Endpoint, Alamofire.Request) -> ()` 在请求发送前的钩子，完全暴露出了 Alamofire 的`Request`对象
- `didReceiveResponse: (Endpoint, Alamofire.Response) -> ()`响应后执行的钩子，完全暴露出了 Alamofire 的`Response<NSData, NSError>`对象

#### `StubBackend`

##### 传统 Moya 风格的`Target`

如果需要 Moya 风格的 Mock，让 API 的声明实现 `TargetWithSample` 替代 `Target`，并且实现 `var sampleResponse: StubResponse { get }` 属性，当后端为`StubBackend`时，就可以使用 API 声明里的默认响应了，`StubResponse`见 [定义](https://github.com/jasl/MoyaX/blob/master/Source/Backends/StubBackend.swift#L12-L21)。

##### 运行时 Stub Target

可以运行时动态的设置Stub，规则是：

动态设置的Stub > API 定义中的响应 > `StubBackend`的默认响应

具体方法见 [定义](https://github.com/jasl/MoyaX/blob/master/Source/Backends/StubBackend.swift#L99-L116)

##### 泛型版本

使用`GenericStubBackend<T: Target>`，这在为使用枚举方式声明的 Targets 在Stub的时候提供了一些便利，具体方法见 [定义](https://github.com/jasl/MoyaX/blob/master/Source/Backends/StubBackend.swift#L173-L189)

## 和 Moya 的差别

### `Target`可以设置更多的属性，并增加默认值

- `baseURL`和`path`外所有属性均为可选，返回值均不为`Optional`
- 可以设置参数的编码方式（即`parameterEncoding`），默认值为`.Form`，支持 Multipart 上传（使用 `.FormWithMultipart）
- 可以设置请求头（即`headerFields`字典）
- 不再包含`sampleData`，如果需要使用 `TargetWithSample`来声明`Targets`，并且`sampleData`被`sampleResponse`取代，其直接接受 [`StubResponse`](https://github.com/jasl/MoyaX/blob/master/Source/Backends/StubBackend.swift#L12-L21)

### `Endpoint`取消泛型

`Endpoint`的泛型并无意义，故取消。

### 不再强制`Target`使用枚举声明

提供非泛型的`MoyaXProvider`来匹配使用类、结构体的`Target`，同时提供了泛型版本`MoyaXGenericProvider`可以按照`Moya`的风格使用。

### 分离`Provider`的职责

`Provider#request`现在只负责串联数据流

#### 将真正处理请求的部分分离到`Backend`

真正处理请求由后端（即`Backend`）完成，目前实现了`AlamofireBackend`和`StubBackend`，这样做还有好处：

- 实现自己的后端很容易，实现`BackendType`协议即可
- 可以增强后端的功能，没有抽象泄漏或者单一职责的负担
- `Provider`可以全局复用

#### `Targete#endpoint`计算属性生成`Endpoint`

可以通过覆写`Target#endpoint`计算属性来实现 Moya 的`Provider#endpointClosure`的功能。

#### 重新设计数据流

`Target`提供API端点的原始定义，转换成结构化的`Endpoint`，用于进一步修饰（如附加 Token）：

`Target` - `Target#endpoint`计算属性 -> `Endpoint`

对`Endpoint`进行修饰，经过中间件后交给`Backend`，同步返回用于取消请求的令牌`Cancellable`：

`Enpoint` - `Provider#prepareForEndpoint` - `middlewares` - `Backend` -> `Cancellable`

### 插件

更改为 `Middleware`

## 为什么要魔改 Moya？

### 强制要求`Target`使用`enum`，而非面向协议

基于泛型的`Provider`搭配枚举时确实方便，因为编辑器和编译器可以进行类型推断，但是在声明`Targets`的时候，就未必方便了，考察 [官方示例](https://github.com/Moya/Moya/blob/master/Demo/Demo/GitHubAPI.swift#L27-L67) ，由于属性需要使用对自身进行枚举（`switch self {}`语法）三个端点的声明中包含了大量的冗余，尤其当端点数量增多时，代码维护的难度会增大。

此外，枚举的`case`的签名要求数据类型和顺序强一致性，并且不允许默认值，这对于复杂端点（如字段可选值、参数存在互斥的情况或者复杂的数据类型）而言，并不是最佳的表达方式。从理论上讲，`Provider`接受的是实现`Target`协议的值、对象，但是`Provider`由于泛型的缘故会与该类型绑定，导致非枚举的情况下`Provider`无法被复用，即使使用枚举类型，由于代码组织的需要，拆分成多个枚举后，`Provider`也是无法复用的，这不合理，再需要更上层封装时（例如需要将`Provider`和其他组件组合），也会增加复杂度。

最后，经过试验可知，拆除`Provider`的泛型约束并不会破坏其功能。

### 用于测试的逻辑和用于生产的杂糅在一起

请看 [Provider#request 实现代码](https://github.com/Moya/Moya/blob/master/Source/Moya.swift#L73-L92)，在生产环境中，是否真实发送请求是通过`StubClosure`来确定的，**更多的代码意味着更多的潜在错误**。

### `Provider`职责过重，数据流不清晰

上一条“用于测试的逻辑和用于生产的杂糅在一起”已经暗示了`Provider`包含了测试和生产两方面职责，然而这还不完全。

当发送真实请求时的数据流（同步）为：

`TargetType` - `endpointClosure` -> `Endpoint<T>` - `requestClosure` -> `NSURLRequest` - `plugins` -> `Alamofire's Request` -> `Cancellable`

测试用途的省略。

两套流程揉在了统一个方法中，单看某一条流程虽然合理，但在代码在表达上非常不直观。

### 难于扩展

由于`Provider`负责一切工作，并且不可变，导致，需要针对特殊场景定制的时候（包括测试需要设置特定的返回），无法操作，只能生成新的`Provider`实例，并且继承`Provider`来做扩展也是难度极大的。

## 许可协议

MIT license.
