### 如何自定义视图的添加与删除的转换方式

在你的设计中，你可以仅仅使用常规的Swift的条件去包含或者排除一个视图。举个例子，你可以通过点击按钮去添加或者删除一些详情的文本：

```swift
struct ContentView: View {
    @State private var showDetails = false

    var body: some View {
        VStack {
            Button("Press to show details") {
                withAnimation {
                    showDetails.toggle()
                }
            }

            if showDetails {
                Text("Details go here.")
            }
        }
    }
}
```

[显示效果](https://www.hackingwithswift.com/img/books/quick-start/swiftui/how-to-add-and-remove-views-with-a-transition-1.mp4)

SwiftUI默认使用淡入淡出的动画去添加或者删除一个视图，但是你可以通过绑定**transition()**修饰符去更改动画效果。

举个例子，我们可以创建几个文本视图，然后赋予它们不同的转换方式，就像下面这样:

```swift
struct ContentView: View {
    @State private var showDetails = false

    var body: some View {
        VStack {
            Button("Press to show details") {
                withAnimation {
                    showDetails.toggle()
                }
            }

            if showDetails {
                // Moves in from the bottom
                Text("Details go here.")
                    .transition(.move(edge: .bottom))

                // Moves in from leading out, out to trailing edge.
                Text("Details go here.")
                    .transition(.slide)

                // Starts small and grows to full size.
                Text("Details go here.")
                    .transition(.scale)
            }
        }
    }
}
```

[显示效果](https://www.hackingwithswift.com/img/books/quick-start/swiftui/how-to-add-and-remove-views-with-a-transition-2.mp4)



### 如何组合转换方式

当你添加或者删除一个视图的时候，使用**combine(with:)**方法，SwiftUI能够让你组合转换的方式来创建一个新的动画效果。

举个例子，你可以创建一个视图，然后让他同时移动和淡出：

```swift
struct ContentView: View {
    @State private var showDetails = false

    var body: some View {
        VStack {
            Button("Press to show details") {
                withAnimation {
                    showDetails.toggle()
                }
            }

            if showDetails {
                Text("Details go here.")
                     .transition(AnyTransition.opacity.combined(with: .slide))
            }
        }

    }
}
```

[显示效果](https://www.hackingwithswift.com/img/books/quick-start/swiftui/how-to-combine-transitions-1.mp4)

为了使组合转换方式更加简单的去使用与复用，你可以创建一个**AnyTransition**的扩展。举个例子，我们可以自定义一个**moveAndScale**的转换方式，然后直接尝试去使用它:

```swift
struct ContentView: View {
    @State private var showDetails = false

    var body: some View {
        VStack {
            Button("Press to show details") {
                withAnimation {
                    showDetails.toggle()
                }
            }

            if showDetails {
                Text("Details go here.")
                     .transition(AnyTransition.opacity.combined(with: .slide))
            }
        }

    }
}
 Download this as an Xcode project


To make combined transitions easier to use and re-use, you can create them as extensions on AnyTransition. For example, we could define a custom moveAndScale transition and try it out straight away:

extension AnyTransition {
    static var moveAndScale: AnyTransition {
        AnyTransition.move(edge: .bottom).combined(with: .scale)
    }
}

struct ContentView: View {
    @State private var showDetails = false

    var body: some View {
        VStack {
            Button("Press to show details") {
                withAnimation {
                    showDetails.toggle()
                }
            }

            if showDetails {
                Text("Details go here.")
                    .transition(.moveAndScale)
            }
        }
    }
}
```

[显示效果](https://www.hackingwithswift.com/img/books/quick-start/swiftui/how-to-combine-transitions-2.mp4)

### 如何创建不对称的转换效果

 SwiftUI可以让我们在添加一个视图的时候，指定一个转换，删除的时候，指定另一个转换，所有的这些都可以通过**asymmetric()**方法去实现。

举个例子，我们能够创建一个使用asymmetric转换修饰的文本视图，当添加的时候，从左边移动进来，当删除的时候，往底部移动，就像下面这样:

```swift
struct ContentView: View {
    @State private var showDetails = false

    var body: some View {
        VStack {
            Button("Press to show details") {
                withAnimation {
                    showDetails.toggle()
                }
            }

            if showDetails {
                Text("Details go here.")
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .bottom)))
            }
        }
    }
}
```

[显示效果](https://www.hackingwithswift.com/img/books/quick-start/swiftui/how-to-create-asymmetric-transitions-1.mp4)

### 如何创建自定义的转换效果

虽然SwiftUI带有一系列内建的转换效果，但是如果我们想的话，完全可以去实现一个完整的自定义转换效果。

整个过程分成三步：

* 创建一个**ViewModifier**去表示任意状态下的转换效果
* 创建一个**AnyTransition**的扩展，我们可以使用上面的修饰器去表示视图活动跟原样状态
* 在你的视图中应用这个转换

下面的代码就是实现如下效果:

[显示效果](https://www.hackingwithswift.com/img/books/quick-start/swiftui/how-to-create-a-custom-transition-1.mp4)

为了实际演示这一点，我将向你展示一个完整的代码示例，该示例执行以下几项操作:

1. 定义一个名为**ScaledCircle**的形状，它将在一个矩形中创建一个圆形，它将根据动画的值对圆形进行缩放。
2. 创建一个自定义的**ViewModifier**结构，让任意的形状（在这个例子中是一个缩放的圆形）在另一个视图中被裁减。
3. 将这个视图修饰器包含在**AnyTransition**的扩展中，便于我们去访问。
4. 创建一个SwiftUI的视图去实际应用这个转换的效果

下面是具体实现的带着注释的的代码：

```swift

    func body(content: Content) -> some View {
        content.clipShape(shape)
    }
}

// A custom transition combining ScaledCircle and ClipShapeModifier.
extension AnyTransition {
    static var iris: AnyTransition {
        .modifier(
            active: ClipShapeModifier(shape: ScaledCircle(animatableData: 0)),
            identity: ClipShapeModifier(shape: ScaledCircle(animatableData: 1))
        )
    }
}

// An example view move showing and hiding a red
// rectangle using our transition.
struct ContentView: View {
    @State private var isShowingRed = false

    var body: some View {
        ZStack {
            Color.blue
                .frame(width: 200, height: 200)

            if isShowingRed {
                Color.red
                    .frame(width: 200, height: 200)
                    .transition(.iris)
                    .zIndex(1)
            }
        }
        .padding(50)
        .onTapGesture {
            withAnimation(.easeInOut) {
                isShowingRed.toggle()
            }
        }
    }
}
```



