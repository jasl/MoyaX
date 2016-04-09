MoyaX
====

[![Build Status](https://travis-ci.org/jasl/MoyaX.svg?branch=master)](https://travis-ci.org/jasl/MoyaX)
[![codecov.io](https://codecov.io/github/jasl/MoyaX/coverage.svg?branch=master)](https://codecov.io/github/jasl/MoyaX?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

**MoyaX 所有特性已经冻结，仍需要补全测试、文档以及代码审查。**

在开发App的时候，通常会使用 Alamofre 或者 NSURLSession 或是其他的网络库来调用服务器端的 API，为了方便使用，聪明的开发者会将 API 调用封装成类。

MoyaX 正是将这一封装的最佳实践提取成框架，来更简单的封装服务器端暴露的 API，特别是针对 Restful 风格的 API。底层使用成熟的 [Alamofire](https://github.com/Alamofire/Alamofire)。此外，MoyaX 视 Stub 请求为一等公民，在开发过程中，你可以很容易的利用本地数据来模拟真实请求，减少对于后端开发的依赖，易于测试。 

MoyaX 派生自著名的网络抽象层框架 [Moya](https://github.com/Moya/Moya)，起初是对 Moya 重构的[试探性思考](Documentation/motivation_zh.md)，如今经过打磨已可用于生产环境开发。

## 设计哲学

MoyaX 仅将网络 API 请求调用与接收这一过程的优秀实现方式抽象成了框架，实际的网络请求发送与接收交给成熟的 Alamofire 来完成，通过更少的实现功能来保证框架本身的稳健。同时，MoyaX 暴露出 Alamofire 的 `Request` 和 `Response` 对象，方便高级使用者的定制。

## 功能

MoyaX 提供了以下功能：

- 用于描述服务器端 API 的协议
- 相比于 `NSMutableRequest` 更易于编辑的请求对象
- 中间件机制，可以插入逻辑到请求发送前和收到响应后，方便实现通知UI、打印日志、编辑请求等
- 若干钩子，方便处理如为请求添加授权信息等问题
- 方便的 Stub 请求
- 文件上传
- 暴露 Alamofire 的 `Request` 对象，方便使用 Alamofire 的 `delegate` 和高级功能

## 安装

### Cocoapods

只需要添加 `pod 'MoyaX'` 到 `Podfile` 中，然后执行 `pod install` 即可。

### Carthage

只需要添加 `github "jasl/MoyaX"` 到 `Cartfile` 中，然后执行 `carthage bootstrap` 即可。

## 基本使用

MoyaX 的基本使用仅需两步。

### 声明服务器端 API

只需要声明一个类、结构体、枚举，使其实现 `Target` 协议，如：

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
  
  // 可以省略，API 的请求方式，默认为 .GET
  var method: HTTPMethod {
    return .GET
  }
  
  // 可以省略，额外的 HTTP 请求头信息，默认为空
  var headerFields: [String: String] {
    return [:]
  }
  
  // 可以省略，HTTP 请求的表单数据，默认为空
  var parameters: [String: AnyObject] {
  	 return [:]
  }
  
  // 可以省略，HTTP 请求的表单数据的编码方式，默认为 .URL，即以 HTTP 表单方式提交 parameters
  var parameterEncoding: ParameterEncoding {
  	 return .URL
  }
}
```

### 通过 `Provider` 发送请求

所有声明好的服务器端 API 都通过 `MoyaXProvider` 来请求和处理响应，最基本的使用方式：

```swift
// 初始化 MoyaXProvider
let provider = MoyaXProvider()

// 发出请求
provider.request(GithubShowUser(name: "jasl")) { response in
  // 在回调中处理响应，response 为枚举
  switch response {
  
  // 服务器有返回结果，注意服务器返回 4xx、5xx 也走这里
  case let .Response(response):
    // 服务器端返回的数据，为 NSData
    let data = response.data
    // 服务器端返回的状态码
    let statusCode = response.statusCode
    // 在这里处理响应
    
  // 网络原因（连通性或者超时）服务器没有返回结果、请求被取消或者其他异常
  case let .Incomplete(error):
    // 在这里处理请求失败，error 是一个枚举
  }
}
```

## 演示项目

`Example` 目录下包含了一个使用 Github API 的示例项目，包含了一些使用技巧，可供参考。

## License

MoyaX 被许可在 MIT 协议下使用。查阅 LICENSE 文件来获得更多信息。
