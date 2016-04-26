MoyaX - a fork of [Moya](https://github.com/Moya/Moya)
====

[![Build Status](https://travis-ci.org/jasl/MoyaX.svg?branch=master)](https://travis-ci.org/jasl/MoyaX)
[![codecov.io](https://codecov.io/github/jasl/MoyaX/coverage.svg?branch=master)](https://codecov.io/github/jasl/MoyaX?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/MoyaX.svg)](https://img.shields.io/cocoapods/v/MoyaX.svg)
[![Platform](https://img.shields.io/cocoapods/p/Alamofire.svg?style=flat)](http://cocoadocs.org/docsets/MoyaX)

[中文版本介绍](Readme_zh.md)

**MoyaX all features are freezed, it still needs more tests, documents and code reviews, please help!**

You're a smart developer. You probably use Alamofire to abstract away access to NSURLSession and all those nasty details you don't really care about. But then, like lots of smart developers, you write ad hoc network abstraction layers. They are probably called "APIManager" or "NetworkModel", and they always end in tears.

So the basic idea of Moya is that we want some network abstraction layer that sufficiently encapsulates actually calling Alamofire directly. It should be simple enough that common things are easy, but comprehensive enough that complicated things are also easy.

Also MoyaX treats test stubs as first-class citizens so unit testing is super-easy.

MoyaX forked Moya originally, but with many refactors, MoyaX has great difference with Moya including:

- Targets no strict using `enum`
- Support MultipartFormData upload
- Expose Alamofire's `Request` and `Response` for advanced usage
- More powerful stubbing request

But MoyaX consider functional and reactive support should become extension, so they'd been removed for now until MoyaX is stable.

## Sample Project

There's a sample project in the `Example` directory. Have fun!

## Requirements

- iOS 8.0+ / Mac OS X 10.9+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 7.3+

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

### Abstract web API into a target

Using MoyaX starts with defining a target – it could be a `struct`, `class` or an `enum` that requires to conform to the `Target` protocol. Then, the rest of your app deals *only* with those targets. a Target is looks like:

```swift
// This struct defined Github show user API
struct GithubShowUser: Target {
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
  
  // Optional, default is .URL, means submitting parameters using `x-www-form-urlencoded`
  var parameterEncoding: ParameterEncoding {
    return .URL
  }
}
```

### Make a request

You should access Targets through `MoyaXProvider`.

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
    
  // Network failure (connectivity or timeout), the request had cancelled or other unexpected errors goes here
  case let .Incomplete(error):
    // error is an enum
    // Handle error here
  }
}
```

### Uploading MultipartFormData

Uploading MultipartFormData is simple and efficient.

```swift
struct UploadingTarget: Target {
  let baseURL = NSURL(string: "https://httpbin.org")!
  let path = "post"
  
  // Remember, .GET doesn't support uploading.
  let method = HTTPMethod.POST

  // Encoding parameters by multipart/form-data
  let parameterEncoding = ParameterEncoding.MultipartFormData

  var parameters: [String: AnyObject] {
    return [
      // MoyaX provides some placeholders for MultipartFormData
      "photo1": FileForMultipartFormData(fileURL: photoFileURL, filename: 'photo1.jpg', mimeType: 'image/jpeg'),
      "photo2": DataForMultipartFormData(data: photoData, filename: 'photo2.jpg', mimeType: 'image/jpeg')
  }
}

// Request a MultipartFormData target is no different with others.
provider.request(UploadingTarget()) { response in
  // Handle response
}
``` 

## License

MoyaX is released under an MIT license. See LICENSE for more information.
