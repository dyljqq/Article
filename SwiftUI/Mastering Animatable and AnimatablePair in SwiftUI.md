### 掌握SwiftUI中的Animatable和AnimatablePair

首先举一个很简单的例子，我们希望修改一个矩形的长宽，那么代码如下：

```swift
struct SimpleRectagle: Shape {
    
    var width: CGFloat
    var height: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: (rect.width - width) / 2, y: (rect.height - height) / 2, width: width, height: height))
        return path
    }
    
}

struct ContentView: View {
    
    @State private var width: CGFloat = 100
    @State private var height: CGFloat = 50
    
    var body: some View {
        SimpleRectagle(width: width, height: height)
            .fill(Color.blue)
            .frame(width: 200, height: 200)
            .onTapGesture {
                withAnimation(
                    .spring(
                        response: 1.0,
                        dampingFraction: 0.5,
                        blendDuration: 1.0
                    )
                ) {
                    width = CGFloat.random(in: 50...250)
                    height = CGFloat.random(in: 50...250)
                }
            }
    }
}
```

但是我们运行这个代码，我们会发现，并没有动画效果，即使我们添加了`withAnimation`来告诉系统，我们是需要对这个变化做动画处理。

### 原因

敲重点，当我们处理自定义的对象的时候，比如自定义的`Shape`，SwiftUI并不知道如何去处理自定义的插值属性，如`Width`和`Height`的初始值和最终值。

### 解决方案

使用`Animatable`协议。

```swift
/// A type that describes how to animate a property of a view.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol Animatable {

    /// The type defining the data to animate.
    associatedtype AnimatableData : VectorArithmetic

    /// The data to animate.
    var animatableData: Self.AnimatableData { get set }
}
```

我们只需要让自定义的`Shape`遵循`Animatable`协议, 然后SwiftUI的动画就能够正常的实现了。如下:

```swift
struct SimpleRectagle1: Shape {
    
    var width: CGFloat
    var height: CGFloat
    
    var animatableData: Double {
        get { return width }
        set { width = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: (rect.width - width) / 2, y: (rect.height - height) / 2, width: width, height: height))
        return path
    }
    
}
```

但是上述的实现，我们会发现一个问题，就是我们只看到了水平方向有动画效果，但是竖直方向上没有。回到代码本身，是我们发现`animatableData`只能提供一个返回值，但是我们需要Width跟Height都有动画效果，也就是说，我们需要animatableData是一个pair。然后我们去翻阅文档就会发现，SwiftUI提供了一个结构体: `AnimatablePair`。

```swift
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@frozen public struct AnimatablePair<First, Second> : VectorArithmetic where First : VectorArithmetic, Second : VectorArithmetic {

    /// The first value.
    public var first: First

    /// The second value.
    public var second: Second
}
```

我这边只摘了实现的一部分，我们可以发现，里面刚好提供了两个值，first跟second, 所以我们可以对上面的方案进行改造，如下：

```swift
struct SimpleRectagle2: Shape, Animatable {
    
    var width: CGFloat
    var height: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(width, height) }
        set {
            width = newValue.first
            height = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: (rect.width - width) / 2, y: (rect.height - height) / 2, width: width, height: height))
        return path
    }
    
}
```

这样，我们就能同时实现水平和竖直方向的动画了。

### 总结

对于任何自定义的视图，或者系统视图，我们都可以通过`Animatable`来让自己的视图动起来！