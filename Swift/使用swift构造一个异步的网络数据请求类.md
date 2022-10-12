## 如何使用异步方法构造一个简易的网络请求库

接下来我们会完成以下的功能：

1. 异步接收网络数据

2. 将网络数据进行解析成对应的model

   	* 解析成json格式

   	* 解析成xml格式（使用XMLParser进行解析）

3. 存储到数据库 or 展示成列表

具体的代码可以在这个项目中查看: [DJGithub](https://github.com/dyljqq/DJGithub)

### 构造一个异步的网络数据请求类

我们查看Apple的文档，会发现苹果在URLSession中提供了一个异步加载网络数据的方法：

```swift
/// Convenience method to load data using an URLRequest, creates and resumes an URLSessionDataTask internally.
    ///
    /// - Parameter request: The URLRequest for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    public func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse)

/// Convenience method to load data using an URL, creates and resumes an URLSessionDataTask internally.
    ///
    /// - Parameter url: The URL for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    public func data(from url: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse)
```

因此我们只需要定义一个方法，输入对应的request或者URL就可以了，如下

```swift
func model<T: DJCodable>(with router: Router, decoder: any Parsable = DJJSONParser<T>()) async throws -> T? {
    guard let request = router.asURLRequest() else { throw DJError.requestError }
    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      if let httpReponse = response as? HTTPURLResponse, httpReponse.statusCode != 200 {
        let dict = ["statusCode": httpReponse.statusCode]
        return try DJDecoder(dict: dict).decode()
      }
      return try await decoder.parse(with: data) as? T
    } catch {
      router.printDebugInfo(with: error)
      throw DJError.dataError
    }
  }
```

1. DJCodable：model必须要遵循的协议，这里我试用的是苹果自带的，Codable协议

2. Router：里面会包含所有的网络请求需要的信息，它也是一个协议，定义如下：

```swift
enum HTTPMethod: String {
  case GET
  case POST
  case PUT
  case DELETE
  case PATCH
}

protocol Router: URLRequestConvertible {
  var baseURLString: String { get }
  var method: HTTPMethod { get }
  var headers: [String: String] { get }
  var parameters: [String: Any] { get }
  var path: String { get }
}
```

​	然后我们定一个遵循这个协议的enum，用来区分不同的request，以请求github相关的方法为例：

```swift
enum GithubRouter: Router {
	case userInfo(String) // 获取用户信息
  
   var baseURLString: String {
    return "https://api.github.com/"
  }
  
  var method: HTTPMethod {
    // 这里可以设置不同的request对应的httpmethod
    switch self {
      default: return .GET
    }
  }
  
  var path: String {
    switch self {
      case .userInfo(let userName): return return "users/\(userName)"
    }
  }
  
  var headers: [String : String] {
    return [
      "Accept": "application/vnd.github+json"
    ]
  }
  
  var parameters: [String : Any] {
    // 给一些需要在body中携带数据的网络请求准备的
    switch self {
    default: return [:]
    }
  }
  
  func asURLRequest() -> URLRequest? {
    func asURLRequest() -> URLRequest? {
      var queryItems: [String: String] = [:]

        // 这里可以设置url后需要携带的参数信息
      switch self {
        default: break
      }
      var request = configURLRequest(with: queryItems)
      // 因为github一些接口需要携带用户的Authorization信息，所以在这里可以设置。
      request?.setValue(ConfigManager.config.authorization, forHTTPHeaderField: "Authorization")
      if !parameters.isEmpty {
        switch method {
        case .POST, .PATCH: request?.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        default: break
        }
      }
      return request
    }
      var request = configURLRequest(with: queryItems)
      request?.setValue(ConfigManager.config.authorization, forHTTPHeaderField: "Authorization")
      if !parameters.isEmpty {
        switch method {
        case .POST, .PATCH: request?.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        default: break
        }
      }
      return request
  }
}
```

最后我们通过组装上面的代码，就可以非常简单的定义一个网络请求了：

```swift
// 定义一个用来接收数据的model
struct User: DJCodable {
  var login: String
  var name: String?
  var id: Int
  var bio: String?
  var avatarUrl: String
  var type: String
  var createdAt: String

  var followers: Int
  var following: Int
  var publicRepos: Int
  var reposUrl: String
  var followingUrl: String
  var followersUrl: String
  
  var company: String?
  var location: String?
  var email: String?
  var blog: String?
  
  var desc: String {
    return isEmpty(by: self.bio) ? "No description provided." : self.bio!
  }
}

let router = GithubRouter.userInfo("dyljqq")
let user: User = try? await APIClient.shared.data(with: router)
print("user: \(user)")
```

### 如何解析网络数据成对应的model

如果网络数据返回的都是JSON数据，那我们可以自己定义一个JSON解析器，就可以一劳永逸了。如下:

```swift
class DJJSONParser<T: DJCodable>: JSONDecoder, Parsable {
  
  typealias DataType = T
  
  override init() {
    super.init()
    self.keyDecodingStrategy = .convertFromSnakeCase
  }
  
  func parse(with data: Data?) async throws -> T? {
    guard let data = data else { return nil }
    do {
      return try self.decode(T.self, from: data)
    } catch {
      throw DJError.parseError("\(error)")
    }
  }
}
```

当然，大家可能注意到了，DJJSONParser这个类，遵循了一个名为Parsable的协议。这个协议非常简单，定义如下：

```swift
protocol Parsable {
  
  associatedtype DataType: DJCodable
  
  func parse(with data: Data?) async throws -> DataType?
}
```

这样如果后面有不同的数据类型，我们都可以构造一个遵循这个协议的解析器。这样，解析网络数据的时候，我们只需要做如下的操作就行了：

```swift
return try await decoder.parse(with: data) as? T
```

那么我们如何解析一个XML数据么？XML的数据相对于JSON数据会复杂一些。我这里选用了苹果自带的**XMLParse**去做解析。

使用如下：

```swift
let parser = XMLParser(data: data)
parser.delegate = self
parser.parse()

// delegate中有对数据做对应的处理的委托方法。

// 这里我们定义一个类来存储对应的数据
class XMLNode {
  var key: String = ""
  var value: String = ""
  var isEnd = false
  var isRoot = false
  var attributeDict: [String: String] = [:]
  var nodes: [XMLNode] = []
  
  var dict: [String: Any] = [:]
  
  init(with key: String) {
    self.key = key
  }
  
  func parseNodes() {
    for node in nodes {
      if node.nodes.isEmpty {
        if node.value.isEmpty {
          dict[node.key] = node.attributeDict
        } else {
          dict[node.key] = node.value
        }
      } else {
        node.parseNodes()
        if let value = dict[node.key] {
          if let items = value as? [[String: Any]] {
            dict[node.key] = items + [node.dict]
          } else {
            dict[node.key] = [value, node.dict]
          }
        } else {
          dict[node.key] = node.dict
        }
      }
    }
  }
}

// 以解析一个简单的xml为例:
// <description>zhangferry,摸鱼周报,iOS,Swift,生活记录</description>
// 开始解析数据 解析出了elementName=description
func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
  // <atom:link href="https://zhangferry.com/atom.xml" rel="self" type="application/rss+xml"/>
 // attributes attributeDict: [String : String] 存储的是href="https://zhangferry.com/atom.xml" rel="self" type="application/rss+xml"标签里的值.
    let node = XMLNode(with: elementName)
    if stack.isEmpty {
      node.isRoot = true
    }
    if !attributeDict.isEmpty {
      node.attributeDict = attributeDict
    }
    stack.append(node)
  }

  // 解析标签数据内容
// 这个方法会不断调用，直到“zhangferry,摸鱼周报,iOS,Swift,生活记录”数据解析完毕
  func parser(_ parser: XMLParser, foundCharacters string: String) {
    let data = string.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .newlines)
    if let topNode = stack.last {
      topNode.value = topNode.value + data
    }
  }

// 当解析标签结束时
// 解析道</description>时， elementName = description
  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    if let topNode = stack.last, topNode.key == elementName {
      let node = stack.removeLast()
      node.isEnd = true
      if node.isRoot {
        rootNode = node
      }
      if let parentNode = stack.last {
        parentNode.nodes.append(node)
      }
    }
  }
  
// 文档解析完成时
  func parserDidEndDocument(_ parser: XMLParser) {
    rootNode?.parseNodes()
    guard var dict = rootNode?.dict else { return }
    /**
    目前已知的xml格式如下：
     format 1:
     <Feed>
            <channel>
                        // data
            </channel>
     </Feed>
     
     format 2:
     <Feed>
      // data
     </Feed>
     */
    if let channel = dict["channel"] as? [String: Any] {
      dict = channel
    }
    do {
      let model = try DJDecoder(dict: dict).decode() as T?
      continuation?.resume(returning: model)
    } catch {
      print("json parse error: \(error)")
    }
  }

// 这样通过这个方法就可以将上面的信息串联起来了。
func parse(with data: Data?) async throws -> T? {
    guard let data = data else { return nil }
    do {
      return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<T?, Error>) in
        self?.continuation = continuation
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
      }
    } catch {
      print("parse error: \(error)")
      return nil
    }
  }
```

以上就构造了一个比较通用的XML解析的类。那么我们怎么使用呢？以摸鱼周报的atom链接为例：

[摸鱼周报](https://zhangferry.com/atom.xml)

```swift
func data<T: DJCodable>(with urlString: String, decoder: any Parsable = DJJSONParser<T>()) async throws -> T? {
  do {
    guard let url = URL(string: urlString) else { return nil }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try? await decoder.parse(with: data) as? T
  } catch {
    print("url session debug info:")
    print("fetch error: \(urlString), error: \(error)")
    print("------------------------")
  }
  return nil
}

let urlString = "https://zhangferry.com/atom.xml"
let rssFeedInfo: RssFeedInfo? = try? await data(with: urlString, decoder: DJXMLParser<RssFeedInfo>())
print("rssFeedInfo: \(rssFeed.entries)")
```

### 存储到数据库 or 展示成列表

定义一个SQLTable的协议，来完成model与数据库中字段的对应：

```swift
protocol SQLTable {
    
  static var tableName: String { get }
  static var fields: [String] { get }
  static var uniqueKeys: [String] { get }
  static var fieldsTypeMapping: [String: FieldType] { get }
  static var needFieldId: Bool { get }
  static var selectedFields: [String] { get }

  var fieldsValueMapping: [String: Any] { get }
  
  func execute()
      
  static func decode<T: DJCodable>(_ hash: [String: Any]) -> T?
    
}
```

定义一个名为RssFeedInfo的结构体:

```swift
struct RssFeedInfo: DJCodable {
  var title: String
  var updated: String
  var link: String
  var entries: [RssFeed]
  
  var lastBuildDate: String?
  var item: [RssFeed]?
  var entry: [RssFeed]?
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.title = try container.decode(String.self, forKey: .title)
    
    var dateString = ""
    if let updated = try? container.decode(String.self, forKey: .updated) {
      dateString = updated
    } else if let updated = try? container.decode(String.self, forKey: .lastBuildDate) {
      dateString = updated
    }
    
    if !dateString.isEmpty, let date = DateHelper.standard.dateFromRFC822String(dateString) {
      self.updated = DateHelper.standard.dateToString(date)
    } else {
      self.updated = dateString
    }
    
    if let link = try? container.decode(String.self, forKey: .link) {
      self.link = link
    } else {
      self.link = ""
    }
    
    if let entries = try? container.decode([RssFeed].self, forKey: .entry) {
      self.entries = entries
    } else if let entries = try? container.decode([RssFeed].self, forKey: .item) {
      self.entries = entries
    } else {
      self.entries = []
    }
  }
}

struct RssFeedLink: DJCodable {
  var href: String?
}

struct RssFeed: DJCodable {
  var id: Int?
  var title: String
  var updated: String
  var content: String
  var link: String
  
  var contentEncoded: String?
  var description: String?
  var pubDate: String?
  var summary: String?

  var rssFeedLink: RssFeedLink?
  
  var atomId: Int?
  
  enum CodingKeys: String, CodingKey {
    case id, title, updated, content, link, atomId, pubDate,
         contentEncoded = "content:encoded", description, rssFeedLink, summary
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.title = try container.decode(String.self, forKey: .title)
    
    var dateString = ""
    if let updated = try? container.decode(String.self, forKey: .updated) {
      dateString = updated
    } else if let pubDate = try? container.decode(String.self, forKey: .pubDate) {
      dateString = pubDate
    }
    
    if !dateString.isEmpty, let date = DateHelper.standard.dateFromRFC822String(dateString) {
      self.updated = DateHelper.standard.dateToString(date)
    } else {
      self.updated = dateString
    }
    
    if let link = try? container.decode(String.self, forKey: .link) {
      self.link = link
    } else if let rssFeedLink = try? container.decode(RssFeedLink.self, forKey: .rssFeedLink) {
      self.rssFeedLink = rssFeedLink
      self.link = rssFeedLink.href ?? ""
    } else {
      self.link = ""
    }
    
    if let content = try? container.decode(String.self, forKey: .content) {
      self.content = content
    } else if let content = try? container.decode(String.self, forKey: .contentEncoded) {
      self.content = content
    } else if let content = try? container.decode(String.self, forKey: .description) {
      self.content = content
    } else if let content = try? container.decode(String.self, forKey: .summary) {
      self.content = content
    } else {
      self.content = ""
    }
    self.atomId = try? container.decode(Int.self, forKey: .atomId)
    self.id = try? container.decode(Int.self, forKey: .id)
  }
}

extension RssFeed: SQLTable {
  static var tableName: String {
    return "rss_feed"
  }
  
  static var fields: [String] {
    return [
      "title", "updated", "content", "link", "atom_id"
    ]
  }
  
  static var fieldsTypeMapping: [String : FieldType] {
    return [
      "title": .text,
      "updated": .text,
      "content": .text,
      "link": .text,
      "atom_id": .bigint,
      "id": .int
    ]
  }
  
  static var selectedFields: [String] {
    return [
      "id", "title", "updated", "content", "link", "atom_id"
    ]
  }
  
  var fieldsValueMapping: [String : Any] {
    return [
      "id": self.id ?? 0,
      "title": self.title,
      "updated": self.updated,
      "content": self.content,
      "link": self.link,
      "atom_id": self.atomId ?? 0
    ]
  }
  
  func update(with rssFeed: RssFeed) {
    guard let rssFeedId = self.id, rssFeedId > 0 else { return }
    let sql = "update \(Self.tableName) set title=\"\(rssFeed.title)\", content=\"\(rssFeed.content)\", updated=\"\(rssFeed.updated)\", link=\"\(rssFeed.link)\" where id=\(rssFeedId)"
    store.execute(.update, sql: sql, type: RssFeed.self)
  }
  
}
```

然后我们就可以解析不同的rssfeed的数据以及存储到对应数据表中。然后通过数据库or网络请求我们就可以很方便的对数据进行展示了。



PS： 某些Atom源中的数据量非常大，因此可以考虑在APP启动时就进行下载，当然是采用异步下载的方式。可以考虑使用**Aync group**

的方式。

##### 其他

有任何不懂的地方欢迎给我留言