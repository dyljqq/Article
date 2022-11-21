## 使用MVVM重构User页面

如题，今天看了[Swift: MVVM Bindings Pattern (2022, Xcode 12, Swift 5, Architecture) - iOS Development](https://www.youtube.com/watch?v=iI0LabCYZJo&ab_channel=iOSAcademy)，里面谈到了MVVM相关的东西，然后我就通过自己的项目做了一个实践。

说下我实践完后对这个的看法吧。然后给出重构前的代码逻辑，跟重构后的，大家自行甄别这个重构是否值得吧。重构的代码在[UserViewController.swift](https://github.com/dyljqq/DJGithub/blob/master/DJGithub/Github/ViewController/User/UserViewController.swift)

先说一下这个页面的构造逻辑吧。其实逻辑很简单，就是我先获取一个用户对象，然后将对应的TableView进行数据的填充。效果图如下:

![](https://raw.githubusercontent.com/dyljqq/DJGithub/master/screenshot/User.png)

但是这个用户对象有两个输入来源:

	* 本地缓存
	* 网络请求

对于有本地缓存的，则优先展示，然后去加载网络数据，获取成功后进行数据的刷新。

那么传统的MVC的方式，我们可能会这么写:

```swift
// 如果存在本地缓存
if let userViewer = ConfigManager.viewer {
  // 赋值，然后配置页面
  self.userViewer = userViewer
  self.loadUserViewerInfo(with: userViewer)
}
    
Task {
  view.startLoading()
  if let viewer = await UserManager.fetchUserInfo(by: self.name) {
    // 网络数据获取成功后，则进行相同的数据配置操作。
    self.userViewer = viewer
    self.loadUserViewerInfo(with: viewer)

    if ConfigManager.checkOwner(by: viewer.login) {
      LocalUserManager.saveUser(viewer)
    }
  } else {
    view.stopLoading()
  }
}
```

看吧，这里就会存在一个问题，就是多个数据源，我们需要进行相同的逻辑操作。当数据源多，并且可能开发人员不熟悉你的这部分代码的时候，就容易产生只改了一个地方，其他的输入来源没有改的现象。当然我们可以将这部分逻辑进行函数的封装，这也是一个解法，但是其实还是不够清晰。MVVM还有个好处其实在于他便与我们进行单元测试（我是很少写的。）

那么用MVVM的话，我们应该怎么写呢？

```swift
// 首先定义一个类，他用于对数据进行绑定
class DJObserverable<T> {
  var value: T? {
    didSet {
      listener?(value)
    }
  }

  private var listener: ((T?) -> Void)?

  init(value: T? = nil) {
    self.value = value
  }

  func bind(_ listener: @escaping (T?) -> Void) {
    self.listener = listener
  }
}

// 然后定义一个ViewModel
struct UserViewModel {
  var userObserver: DJObserverable<UserViewer> = DJObserverable()

  var userViewer: UserViewer? {
    return userObserver.value
  }

  func fetchUser(with name: String) async {
    if name.isEmpty || ConfigManager.checkOwner(by: name),
       let userViewer = ConfigManager.viewer {
      userObserver.value = userViewer
    }

    if let viewer = await UserManager.fetchUserInfo(by: name) {
      userObserver.value = viewer
      if ConfigManager.checkOwner(by: viewer.login) {
        LocalUserManager.saveUser(viewer)
      }
    }
  }

  mutating func update(_ userViewer: UserViewer?) {
    userObserver.value = userViewer
  }
}

// 最后将更新逻辑注册放到一起
self.userViewModel.userObserver.bind { [weak self] userViewer in
  DispatchQueue.main.async {
    self?.loadUserViewerInfo(with: userViewer)
    self?.tableView.reloadData()
  }
}

// 调用的时候
if let userViewer {
  userViewModel.update(userViewer)
} else {
  Task {
    view.startLoading()
    await userViewModel.fetchUser(with: name)
  }
}
```

从上面的代码，我们可以看出，我们又新增了一个输入来源，这个输入来源是一个从外部传入的完整的User结构，但是我们几乎不用改什么代码，只需要将执行`userObserver.value = userViewer`, 就可以达到我们想要的效果。

当然MVVM也有自己的缺点吧，比如如果页面出现了我们不想要的效果的时候，我们排查原因可能会比较麻烦，毕竟输入源比较多。类似于多线程。所以日常开发中，大家可以自己去做取舍吧。