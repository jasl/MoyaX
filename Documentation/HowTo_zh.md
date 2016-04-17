MoyaX HowTo
====

这里记录了若干技巧，欢迎补充。

## 上传

需要注意的是：MoyaX 支持 `multipart/form-data` 但不支持单文件上传。

```swift
struct UpdateUserProfile: Target {
  let id: String
  let avatarFile: NSURL
  let name: String

  // 构造函数
  init(id: String, name: String, avatarFileURL: NSURL) {
    self.id = id
    self.name = name
    self.avatarFileURL = avatarFileURL
  }

  // 必须实现，API 的地址
  var baseURL: NSURL {
    return NSURL(string: "https://api.github.com")!
  }

  // 必须实现，API 的路径
  var path: String {
    return "/users/\(self.id)"
  }

  // 根据 API 要求来设定，记得只有 .POST .PUT .PATCH 方式请求才可以使用上传
  var method: HTTPMethod {
    return .PATCH
  }

  // 可以省略，额外的 HTTP 请求头信息，默认为空
  var headerFields: [String: String] {
    return [:]
  }

  // 表单数据
  var parameters: [String: AnyObject] {
    return [
      "name": self.name,
      // 附件，另有 DataForMultipartFormData
      "avatar": FileForMultipartFormData(fileURL: self.avatarFileURL, filename: 'avatar.jpg', mimeType: 'image/jpeg')
  }

  // 以 multipart/form-data 方式提交 parameters
  var parameterEncoding: ParameterEncoding {
     return .MultipartFormData
  }
}
```

## 简化 Target 声明

这其实是 Swift 的技巧，当属性为常量或者非计算属性时，可以直接用赋值语句代替 `var propertyName: PropertyType { return val }` 冗长的语句。

```swift
struct HelloAPI: Target {
  let baseURL = NSURL("http://mysite.com")!
  let path = "hello"
}

```