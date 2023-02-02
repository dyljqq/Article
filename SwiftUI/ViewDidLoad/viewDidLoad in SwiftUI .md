### 在SwiftUI中与UIKit VC中的viewDidLoad方法等价的是什么？

如果你使用UIKit中开发过App，那么你一定会想知道，SwiftUI中与viewDidLoad方法等价的是什么。

坏消息是，SwiftUI没有能直接取代viewDidLoad()的方法。

最接近的方法是`OnAppear()`和`onDisAppear()`,这两个方法相当于UIKit中的`viewDidAppear()`和`viewDidDisAppear()`。

如果你真的想要`viewDidLoad()`方法的行为，那么你必须自己实现它。幸运的是，实现流程并不是非常复杂。

### SwiftUI中的viewDidLoad

我们可以使用SwiftUI中的`onAppear()`中的修饰器去模拟`viewDidLoad()`行为。

要实现`viewDidLoad`方法，我们需要完成以下两点:

1. 我们需要知道视图是什么时候加载的。在这个例子中，我们可以使用`onAppear()`修饰器。它可能无法传递确切的意义，但是我认为这是最接近UIKit中的视图加载。
2. 我们在这个视图的生命周期中，只能加载一次。既然我们想要知道它是不是第一次出现，那么我们需要在视图中保存一个状态值。`@State`变量对于内部状态，即只在这个视图中使用，的改变非常完美。

举个例子，我将会在`SpyView`中尝试去实现`viewDidLoad()`方法。

```swift
import SwiftUI

struct SpyView: View {
    
    @State private var viewDidLoad = false
    
    var body: some View {
        Text("Spy")
            .onAppear {
                print("onAppear")
                if viewDidLoad {
                    viewDidLoad = true
                    print("viewDidLoad")
                }
            }
    }
}
```

1. 首先我们创建了一个`@State`变量去记录我们是否已经执行过了`onAppear`行为。
2. 我们使用`onAppear`修饰器去检测视图是否已经显示/加载。
3. 如果viewDidLoad变量是false，那么就意味着`onAppear`方法第一次被调用。
4. 然后我们将`viewDidLoad`变量置为true，然后执行只属于`viewDidLoad`的逻辑。

为了测试它，我将`SpyView`放到navigation视图中。然后进入到详情视图，当返回时，将会触发`onAppear`行为。

```swift
struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("Push to Detail") {
                    Text("Detail")
                        .font(.largeTitle)
                }
                SpyView()
            }
            .font(.largeTitle)
        }
    }
}
```

当App加载完成的时候，你会看到调试窗口中同时出现"OnAppear"和"viewDidLoad"。

但是当视图消失后，再出现，我们会发现，并不会触发`viewDidLoad`中的逻辑。

### 将viewDidLoad写成视图装饰器

每次都实现上面的逻辑看起来非常麻烦。如果你将会多次使用它，那么将它制作成一个视图装饰器会是一个非常好的选择。

我将会创建`onViewDidLoad`修饰器。

首先我们创建一个新的`ViewModifier`。我们可以从前面的例子中拷贝大多数的代码。

```swift
struct ViewDidLoadModifier: ViewModifier {
    
    @State private var viewDidLoad = false
    
    let action: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if viewDidLoad == false {
                    viewDidLoad = true
                    action?()
                }
            }
    }
}
```

然后我们创建一个视图的扩展，来更方便的使用它。我在这里拷贝了`onAppear`的函数签名:

```swift
extension View {
    func viewDidLoad(perform action: (() -> Void)? = nil) -> some View {
        return modifier(ViewDidLoadModifier(action: action))
    }
}
```

上面就是所有的你需要创建一个可重用的`viewDidLoad`装饰器的步骤。下面是如何使用它：

```swift
var body: some View {
    NavigationView {
        VStack {
            NavigationLink("Push to Detail") {
                Text("Detail")
                    .font(.largeTitle)
            }
            SpyView()
                .onAppear {
                    print("onAppear")
                }
                .viewDidLoad {
                    print("viewDidLoad")
                }
        }
        .font(.largeTitle)
    }
}
```



**Thx for reading.**