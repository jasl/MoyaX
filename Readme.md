MoyaX - a fork of [Moya](https://github.com/Moya/Moya)
====

[![Build Status](https://travis-ci.org/jasl/MoyaX.svg?branch=master)](https://travis-ci.org/jasl/MoyaX)
[![codecov.io](https://codecov.io/github/jasl/MoyaX/coverage.svg?branch=master)](https://codecov.io/github/jasl/MoyaX?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

[中文版本介绍](Readme_zh.md)

**MoyaX all features are freezed, it's need to complete tests, documents and code reviews, please help!**

You're a smart developer. You probably use Alamofire to abstract away access to NSURLSession and all those nasty details you don't really care about. But then, like lots of smart developers, you write ad hoc network abstraction layers. They are probably called "APIManager" or "NetworkModel", and they always end in tears.

So the basic idea of Moya is that we want some network abstraction layer that sufficiently encapsulates actually calling Alamofire directly. It should be simple enough that common things are easy, but comprehensive enough that complicated things are also easy.

Also MoyaX treats test stubs as first-class citizens so unit testing is super-easy.

MoyaX forked Moya originally, but with many rethinkings and refactors, MoyaX has great difference with Moya:

- Targets no strict using `enum`
- Support multipart upload
- Expose Alamofire's `Request` and `Response` for advanced usage

## Sample Project

There's a sample project in the `Example` directory. Have fun!

## Installation

### CocoaPods

Just add `pod 'MoyaX'` to your Podfile and go!

Then run `pod install`.

### Carthage

Carthage users can point to this repository

```
github "jasl/MoyaX"
```

## Basic usage

### Declare a remote API (target)

First, you can declare a `struct`, `class` or an `enum` and let it conform `TargetType` protocol to store remote API's informations.

```swift
// This struct defined Github show user API
struct GithubShowUser: TargetType {
  // The username which should requesting
  let name: String
  
  // Constructor
  init(name: String) {
    self.name = name
  }
  
  // Required
  var baseURL: NSURL {
    return NSURL(string: "https://api.github.com")!
  }
  
  // Required
  var path: String {
    return "/users/\(name)"
  }
  
  // Optional, default is .GET
  var method: HTTPMethod {
    return .GET
  }
  
  // Optional, default is empty
  var headerFields: [String: String] {
    return [:]
  }
  
  // Optional, default is empty
  var parameters: [String: AnyObject] {
  	 return [:]
  }
  
  // Optional, default is .Form, means submit parameters using form-data
  var parameterEncoding: ParameterEncoding {
  	 return .Form
  }
}
```

## Request a remote API

You can access APIs through `MoyaXProvider`.

```swift
// Initialize a MoyaXProvider
let provider = MoyaXProvider()

// Request an API
provider.request(GithubShowUser(name: "jasl")) { response in
  switch response {
  
  // The server has response, 4xx and 5xx goes here too
  case let .Response(response):
    let data = response.data
    let statusCode = response.statusCode
    // Handle success here
    
  // Network failure (connectivity or timeout), the request had cancelled or aborted or other unexpect errors goes here
  case let .Incomplete(error):
    // error is an enum
    // Handle error here
  }
}
```

## License

MoyaX is released under an MIT license. See LICENSE for more information.
