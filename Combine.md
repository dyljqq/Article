# Combine: 开始

[原文链接](https://www.raywenderlich.com/7864801-combine-getting-started)

学习怎么使用Combine的发布者与订阅者去处理事件流，合并多个发布者以及更多。

Combine是一个苹果用来处理事件的新的响应式框架，它在WWDC 2019被公布。你可以使用Combine去统一和简化在处理类似于委托，通知，定时器，回掉等事情的代码。iOS目前已经有第三方的响应式框架了，但是苹果现在发布了自己的新的框架。

在这个教程中，你将会学到下面这些：

* 使用Publisher 和 Subscriber。
* 处理事件流。
* 使用Combine的处理方式去使用Timer。
* 确认什么时候在项目中使用Combine。

你将会看到这些核心概念在实际项目中的应用，FindOrLose这个游戏会挑战你在快速在四张图片中识别出一张不同图片。

准备好在iOS的Combine的魔法世界中探索了么？是时候让我们去学习了。

### 开始学习

首先下载对应的项目内容。[下载内容](https://koenig-media.raywenderlich.com/uploads/2020/04/FindOrLose.zip)

打开名叫starter的项目，然后检查里面的文件。

在你可以玩这个游戏之前，你需要在[Unsplash Developers](https://unsplash.com/developers)中注册，并获取到对应的API key。在注册之后，你将会需要在它们的开发者网站上去创建一个App。一旦完成之后，你将会在屏幕上看到下面：

![](https://koenig-media.raywenderlich.com/uploads/2020/01/FinalUnsplashFindOrLose.jpg)

```
注意：Unsplash APIs每个小时只能调用50次：我们的游戏非常有趣，但是请避免过度玩它。
```

打开Unsplash.swift，并且添加你的UnSplash API key到UnSplashAPI.accessToken：

```
enum UnsplashAPI {
  static let accessToken = "<your key>"
  ...
}
```

编译然后运行。主屏幕上会显示四个灰色的方块。你也会看到一个用于开启和暂停游戏的按钮：

![](https://koenig-media.raywenderlich.com/uploads/2020/01/StartScreen-231x500.png)

按下Play按钮去开启游戏：

![](https://koenig-media.raywenderlich.com/uploads/2020/01/StartGaming-231x500.png)

现在，这是一个完整可以工作的游戏，但是，让我们看看GameViewController.swift中的playGame()。这个方法的结尾是这样的：

```
            }
          }
        }
      }
    }
  }
```

 这里有太多的嵌套闭包。你可以弄清楚发生了什么，然后它们的调用顺序么？如果你想要改变事情发生的顺序，或者退出，或者添加新的函数该怎么办？现在就是我们学习Combine去帮助我们解决这种困境的时候。

### 介绍Combine

Combine框架提供了一个可声明的API去处理值。它有三个主要的模块：

1. Publishers：产生值。
2. Operators：处理值。
3. Subscribles：关注值。

依次来看这三个模块：

#### Publishers（发布者）

发布者对象会随时间会传递一系列值。这个协议有两个关联类型：Output，生产值的类型，以及Failure，用来处理它产生错误的类型。

每个发布者都可以发布多个事件：

* 输出值的输出类型
* 处理成功后的回调
* 发生错误时输出错误类型

许多Foudation类型已经支持发布者的功能，包括Timer以及URLSession，这些也会出现在我们的教程中。

#### Operators（操作者）

Operators是一种被发布者们调用的特殊的方法，然后会返回相同或者不同的发布者。一个操作描述了一种增删改，以及其他操作的行为。你可以链接不同的操作，然后去处理复杂的处理流程。

想象一下值通过原始的发布者流出后，经过一系列的操作后输出。就像一条河流，值从上流的发布者，流到了下流的发布者。

#### Subscribles（订阅者）

发布者和操作都是无意义的，除非一些事情将会监听发布者事件。这个就是我们将要介绍的订阅者。

订阅者是另一个协议。像发布者一样，它有两个关联类型：Input和Failure。它们必须匹配发布者的Output和Failure。

一个订阅者接收一系列发布者的值，回调和错误事件。

#### 将它们整合到一起

当你调用subscribe(_:)时，一个发布者开始传递值，然后传递给订阅者。换句话说，就是一个发布者发送一个订阅事件给订阅者。订阅者可以使用这个订阅事件去发送一个请求去获取有限或者无穷的值。

这样之后，发布者可以自由的向订阅者发布消息。它可以传递全部的请求值，也可以只发送一部分。如果发布者是有限的，那么它最终会返回一个完成事件，或者一个可能的错误。这个流程图就总结了这个过程：

![](https://koenig-media.raywenderlich.com/uploads/2020/01/Publisher-Subscriber-474x500.png)

#### 使用Combine进行网络请求

上面快速的给了一些Combine的直观感受。现在是我们开始在我们的项目中使用它的时候了。

首先，你需要创建一个GameError的enum类型去处理所有的发布者错误。从Xcode的主菜单中，选择文件->新建->文件。。。然后选择模板：iOS->Source->Swift File。

给新文件命名为GameError.swift，然后加入到Gamer的文件夹中。

现在添加GameError的enum：

```swift
enum GameError: Error {
  case statusCode
  case decoding
  case invalidImage
  case invalidURL
  case other(Error)
  
  static func map(_ error: Error) -> GameError {
    return (error as? GameError) ?? .other(error)
  }
}
```

这里罗列了所有你在游戏过程中可能会产生的错误，添加了一个便捷的方法去处理任意错误类型的函数，确保输出一个GameError。当你执行你的发布者的时候，你将会使用到它。

紧接着，你就可以准备好去处理HTTP状态码以及解码错误了。

接下来，引入Combine。打开UnsplashAPI.swift，然后将下面这行代码添加到文件的最上方：

```swift
import Combine
```

然后改变下面这个函数的签名：

```swift
static func randomImage() -> AnyPublisher<RandomImageResponse, GameError> {
```

现在，这个方法不再提供一个完成闭包的参数。取而代之的是，它返回一个有RandomImageResponse和GameError类型的发布者。

AnyPublisher是一个系统类型，你可以使用它去包裹任何发布者。如果你使用计算者，它可以让你去更新你的方法签名，或者如果你想要隐藏调用者的细节。

接下来，你将会使用URLSession的新的Combine功能去更新你的代码。找到session.dataTask(with:函数的起始位置。用下面的代码替换从这行到方法结束部分：

```swift
// 1
return session.dataTaskPublisher(for: urlRequest)
  // 2
  .tryMap { response in
    guard
      // 3
      let httpURLResponse = response.response as? HTTPURLResponse,
      httpURLResponse.statusCode == 200
      else {
        // 4
        throw GameError.statusCode
    }
    // 5
    return response.data
  }
  // 6
  .decode(type: RandomImageResponse.self, decoder: JSONDecoder())
  // 7
  .mapError { GameError.map($0) }
  // 8
  .eraseToAnyPublisher()
```

这看起来是用了很多代码，但是它使用了很多Combine的特性。以下是分步说明：

1. 你从URL请求中获取一个发布者。它是URLSession.DataTaskPublisher，输出类型是(data: Data, response: URLResponse)。它不是一个正确的输出类型，因此你需要做下面一系列的操作去获得你想要获得输出值。
2. 应用tryMap操作。这个操作将拿到上流输出的值，然后尝试着将它转化为另一种类型，并且可能会抛出错误。也有map算子用于转化数据但是不抛出错误。
3. 检查HTTP返回码是不是200。
4. 如果你没有获得一个状态码为200的HTTP状态，那么就抛出一个自定义的GameError.statusCode。
5. 如果所有事情都是OK的就返回response.data。这意味着你现在输出链上的输出结果类型是Data。
6. 应用decode操作，它将会把上流的数据通过JSONDecoder转化为RandomImageResponse。你现在的输出类型是正确的！
7. 你的错误类型一直不是非常正确的。如果你在解码的时候产生了一个错误，它将不是一个GameError。你将通过MapError这个函数对这个错误进行处理，然后通过GameError中的map方法将错误转化成你想要的错误类型。
8. 如果你此时想要检查mapError的返回类型，你将会发现一些非常可怕的东西。.eraseToAnyPublisher方法会把所有的情况都合并到一起，然后输出一些有用的东西。

现在你可以把所有这些都写到一个操作中去，但是这不是Combine的灵魂。你可以思考一下它，就像UNIX 工具一样，每一步都做一件事情，然后传递处理的结果。

#### 使用Combine下载图片

既然你已经有了网络下载的逻辑，那么是时候去下载一些图片了。

打开*ImageDownloader.swift* 图片，在文件最开始的地方引入Combine框架，如下：

```swift
import Combine
```

就像randomImage函数一样，你使用Combine时，函数不需要闭包参数。用如下代码替换download(url:, completion:)：

```swift
// 1
static func download(url: String) -> AnyPublisher<UIImage, GameError> {
  guard let url = URL(string: url) else {
    return Fail(error: GameError.invalidURL)
      .eraseToAnyPublisher()
  }

  //2
  return URLSession.shared.dataTaskPublisher(for: url)
    //3
    .tryMap { response -> Data in
      guard
        let httpURLResponse = response.response as? HTTPURLResponse,
        httpURLResponse.statusCode == 200
        else {
          throw GameError.statusCode
      }
      
      return response.data
    }
    //4
    .tryMap { data in
      guard let image = UIImage(data: data) else {
        throw GameError.invalidImage
      }
      return image
    }
    //5
    .mapError { GameError.map($0) }
    //6
    .eraseToAnyPublisher()
}

```

这部分代码非常像上面那部分的代码。下面就是分步解析：

1. 像之前一样，改变函数签名，函数不再接收一个闭包参数，而是返回一个发布者。
2. 通过图片URL获得一个dataTaskPublisher
3. 使用tryMap去检查响应的状态码，如果都OK的话，那么就提炼这部分数据。
4. 使用另一个tryMap，去将Data转化为UIImage，如果转化失败的话，就抛出错误。
5. 将错误映射为GameError。
6. 使用.eraseToAnyPublisher返回一个合适的类型。

#### 使用Zip

此时，你已经将所有网络请求的方法都改成了使用发布者的方式，而不是使用闭包参数。现在就让我们去使用它们吧。

打开*GameViewController.swift*.，在文件的开始位置引入Combine框架：

```swift
import Combine
```

在GameViewController类中开始的位置加上：

```swift
var subscriptions: Set<AnyCancellable> = []
```

你将会使用这个属性去存储所有的订阅者。到目前为止，你已经处理了发布者和操作者，但是没有涉及到订阅者。

现在，删除playGame函数中的在startLoaders()后的所有代码，然后替换成如下的代码：

```swift
// 1
let firstImage = UnsplashAPI.randomImage()
  // 2
  .flatMap { randomImageResponse in
    ImageDownloader.download(url: randomImageResponse.urls.regular)
  }

```

通过上面的代码，你实现了如下功能：

1. 获得了一个会提供一张随机图片给你的发布者。
2. 应用flatMap操作，这个操作将值从一个发布者转化为另一个新的发布者。在这个例子中，你调用randomImage函数产生一个输出，然后将这个输出通过图片下载函数转化为一个发布者。

接下来，你使用跟上面相同的逻辑，获得另一张图片发布者。在firstImage下面添加如下代码：

```swift
let secondImage = UnsplashAPI.randomImage()
  .flatMap { randomImageResponse in
    ImageDownloader.download(url: randomImageResponse.urls.regular)
  }

```

此时，你已经下载了两张随机的图片。是时候将它们合并到一起了。你会使用zip去做这个操作。在secondImage下面添加如下代码：

```
// 1
firstImage.zip(secondImage)
  // 2
  .receive(on: DispatchQueue.main)
  // 3
  .sink(receiveCompletion: { [unowned self] completion in
    // 4
    switch completion {
    case .finished: break
    case .failure(let error): 
      print("Error: \(error)")
      self.gameState = .stop
    }
  }, receiveValue: { [unowned self] first, second in
    // 5
    self.gameImages = [first, second, second, second].shuffled()

    self.gameScoreLabel.text = "Score: \(self.gameScore)"

    // TODO: Handling game score

    self.stopLoaders()
    self.setImages()
  })
  // 6
  .store(in: &subscriptions)

```

这是分解报告：

1. zip通过合并已经存在的发布者产生一个新的发布者。它将会一直等，直到两个发布者都发射出值，然后它会将值传递到下面的流中。
2. receive(on:)操作允许你指定上面的事件在什么地方进行处理。因为涉及到了UI操作，所以你将会在主线程中使用它。
3. 这是你的第一个订阅者！sink(receiveCompletion:receiveValue:)将会你创建一个订阅者，它将会执行两个闭包，一个是完成闭包，一个是处理接收值的闭包。
4. 你的发布者通过这两种方式完成-结束或者失败。如果失败了，就停止游戏。
5. 当你接收到两张随机的图片的时候，将它们添加到一个数据，并随机打乱，然后更新UI。
6. 在subscriptions中存储这个订阅者。在不保持这个引用的情况下，这个订阅者会取消或者发布者会立即结束。

最后，编译然后运行：

![](https://koenig-media.raywenderlich.com/uploads/2020/01/GameWithCombine-231x500.png)

恭喜你，你的app已经成功使用Combine去处理事件流了。

### 添加分数

你可能已经注意到了，记分工作不再工作了。之前，当你正在选择正确的图片时，你的分数将会被分数会出现倒计时。你将会使用Combine去重新构建定时器功能。

首先，将playGame中的// TODO: Handling game score替换为如下代码：

```swift
self.gameTimer = Timer
  .scheduledTimer(withTimeInterval: 0.1, repeats: true) { [unowned self] timer in
  self.gameScoreLabel.text = "Score: \(self.gameScore)"

  self.gameScore -= 10

  if self.gameScore <= 0 {
    self.gameScore = 0

    timer.invalidate()
  }
}
```

上面的代码，你的调度变量gameTimer将会每0.1秒出发一次，并且每次分数都将减少10。当你的分数变为0时，你讲停止使用定时器。

现在，编译并运行这个去确认游戏分数随着时间在减少。

#### 通过Combine构建定时器

定时器是另一种Foundation类型，Combine在这上面添加了自己的功能。你将会迁移到Combine版本，去看它们的差别。

在GameViewController的上面，改变gameTimer的定义：

```swift
var gameTimer: AnyCancellable?
```

你现在存储了一个定时器的订阅者，而不是定时器本身。这能够被Combine中的AnyCancellable所替代。

用下面的代码改变playGame()和stopGame()方法的第一行。

```swift
gameTimer?.cancel()
```

现在，用下面的代码改变playGame()中的gameTimer的赋值：

```swift
// 1
self.gameTimer = Timer.publish(every: 0.1, on: RunLoop.main, in: .common)
  // 2
  .autoconnect()
  // 3
  .sink { [unowned self] _ in
    self.gameScoreLabel.text = "Score: \(self.gameScore)"
    self.gameScore -= 10

    if self.gameScore < 0 {
      self.gameScore = 0

      self.gameTimer?.cancel()
    }
  }
```

下面是分步解释：

1. 你使用定时器的新的发布者API。在给定的runloop中，发布者将会重复不断的按照给定的时间间隔执行。
2. 这个发布者是一种特殊的发布者，需要我们明确告知是开始还是暂停。.autoconnect操作关注，只要订阅事件开始或者取消，这个操作就会对应连接还是断开连接。
3. 这个发布者不会出错，因此不需要处理完成事件。这个例子中，sink只会处理你提供的处理值的闭包。

编译并且运行app，然后玩你的Combine App。

### 完善应用程序

这里缺失了一些改进。你只是通过.store(in: &subscriptions)添加了订阅者，但是却没有删除它们。你后面将会修复这个。

在resetImages()中添加：

```
subscriptions = []
```

这里，你赋值了一个空的数组，它将会移除所有未使用的订阅者。

接下来，在stopGame()中添加：

```swift
subscriptions.forEach { $0.cancel() }
```

这里，你迭代了整个subscriptions，并且取消它们。

是时候去最后一次运行我们的应用了！

![](https://koenig-media.raywenderlich.com/uploads/2020/01/FinalGameGIF-1.gif)

