### 如何给View添加红点

首先我们给View添加一个扩展，如下:

```swift
extension View {
    func badge(count: Int?) -> some View {
        overlay(
            ZStack {
                if let count, count > 0 {
                    Circle()
                        .fill(Color.red)
                    Text("\(count)")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            .offset(CGSize(width: 12, height: -12))
            .frame(width: 24, height: 24),
            alignment: .topTrailing
        )
    }
}
```

然后我们就可以通过这个扩展给对应的View添加红点了。示例如下:

```swift
VStack {
    Text("Hello")
        .font(Font.system(size: 50))
        .padding()
        .background(Color(white: 0.8))
        .badge(count: 5)
}
```

效果图如下:

![](/Users/polarisdev/Desktop/OpenSource/MyGithub/Article/SwiftUI/badge.jpg)