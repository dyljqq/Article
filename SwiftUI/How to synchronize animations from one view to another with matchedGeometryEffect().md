# 如何使用matchedGeometryEffect方法同步不同视图的动画

[How to synchronize animations from one view to another with matchedGeometryEffect()](https://www.hackingwithswift.com/quick-start/swiftui/how-to-synchronize-animations-from-one-view-to-another-with-matchedgeometryeffect)

#### 更新到Xcode 14.2

如果你有同一个视图在不同的视图层级中显示，然后你想要在他们之间做动画，举个例子，从视图列表转到详情视图，那么你应该使用SwiftUI提供的**matchedGeometryEffect()**修饰器，它有点像KeyNote中的Magic Move。

将这个修饰器关联到不同试图层级中的一对相同的视图。当关联完后，你在这两个视图中进行切换，你会发现SwiftUI会提供非常平滑的动画效果。

为了尝试这个效果，首先我们要创建一系列的相同视图出现在不同位置的布局。就这个例子来说，我有一个红色的圆形，然后一个会跟着一个文本视图，但是在另一个视图状态，这个视图会在文本视图的后面，并且会改变颜色：

```swift
struct ContentView: View {
    @State private var isFlipped = false

    var body: some View {
        VStack {
            if isFlipped {
                Circle()
                    .fill(.red)
                    .frame(width: 44, height: 44)
                Text("Taylor Swift – 1989")
                    .font(.headline)
            } else {
                Text("Taylor Swift – 1989")
                    .font(.headline)
                Circle()
                    .fill(.blue)
                    .frame(width: 44, height: 44)
            }
        }
        .onTapGesture {
            withAnimation {
                isFlipped.toggle()
            }
        }
    }
}
```

<video id="video" controls="" preload="none" poster="封面">
      <source id="mp4" src="https://www.hackingwithswift.com/img/books/quick-start/swiftui/how-to-synchronize-animations-from-one-view-to-another-with-matchedgeometryeffect-1.mp4" type="video/mp4">
</videos>
</video>

当你运行它的时候，你会看到这些视图淡入淡出的效果 - 这是可以的，但是你还可以做的更好。

首先，你需要使用`@NameSpace`属性包装器去为你的视图创建一个全局的命名空间。实际上它只是你视图上的一个属性，但是在幕后，这可以将它们绑定在一起。

所以你可以像这样添加一个属性： `@Namespace private var animation`.

接下来你可以添加**.matchedGeometryEffect(id: YourIdentifierHere, in: animation)**到所有你想要同步动画效果的视图上。**YourIdentifierHere**应该替换成你想要共享的唯一编号。

在我们的例子中，我可能会在圆形视图上添加它：

```swift
.matchedGeometryEffect(id: "Shape", in: animation)
```

并且给文本视图添加它：

```swift
.matchedGeometryEffect(id: "AlbumTitle", in: animation)
```

这么做了之后，当你运行代码的时候，你会看到两个视图之间的移动是非常平滑的。

下面是最终的代码:

```swift
struct ContentView: View {
    @Namespace private var animation
    @State private var isFlipped = false

    var body: some View {
        VStack {
            if isFlipped {
                Circle()
                    .fill(.red)
                    .frame(width: 44, height: 44)
                    .matchedGeometryEffect(id: "Shape", in: animation)
                Text("Taylor Swift – 1989")
                    .matchedGeometryEffect(id: "AlbumTitle", in: animation)
                    .font(.headline)
            } else {
                Text("Taylor Swift – 1989")
                    .matchedGeometryEffect(id: "AlbumTitle", in: animation)
                    .font(.headline)
                Circle()
                    .fill(.blue)
                    .frame(width: 44, height: 44)
                    .matchedGeometryEffect(id: "Shape", in: animation)
            }
        }
        .onTapGesture {
            withAnimation {
                isFlipped.toggle()
            }
        }
    }
}
```

<video id="video" controls="" preload="none" poster="封面">
      <source id="mp4" src="https://www.hackingwithswift.com/img/books/quick-start/swiftui/how-to-synchronize-animations-from-one-view-to-another-with-matchedgeometryeffect-2.mp4" type="video/mp4">
</videos>

下面是一个更高级的例子，尝试下它 - 它借鉴了Apple Music中的专辑展示的样式，当你点击视图的时候，展开它，然后呈现出更大的视图。这个例子中，只有文本视图是有动画的，因为只有它改变了位置。

```swift
For a more advanced example, try this – it borrows the album display style from Apple Music, expanding a small view up to something larger when tapped. In this example only the text is animated because it’s changing location:

struct ContentView: View {
    @Namespace private var animation
    @State private var isZoomed = false

    var frame: Double {
        isZoomed ? 300 : 44
    }

    var body: some View {
        VStack {
            Spacer()

            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.blue)
                        .frame(width: frame, height: frame)
                        .padding(.top, isZoomed ? 20 : 0)

                    if isZoomed == false {
                        Text("Taylor Swift – 1989")
                            .matchedGeometryEffect(id: "AlbumTitle", in: animation)
                            .font(.headline)
                        Spacer()
                    }
                }

                if isZoomed == true {
                    Text("Taylor Swift – 1989")
                        .matchedGeometryEffect(id: "AlbumTitle", in: animation)
                        .font(.headline)
                        .padding(.bottom, 60)
                    Spacer()
                }
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    isZoomed.toggle()
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .background(Color(white: 0.9))
            .foregroundColor(.black)
        }
    }
}
```

<video id="video" controls="" preload="none" poster="封面">
      <source id="mp4" src="https://www.hackingwithswift.com/img/books/quick-start/swiftui/how-to-synchronize-animations-from-one-view-to-another-with-matchedgeometryeffect-3.mp4" type="video/mp4">
</videos>

#### 好了，我要出门拍❄️了。Good Bye！

