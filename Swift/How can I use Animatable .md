# How can I use Animatable

Do you know the `Animatable Protocol` in SwiftUI？ It controls the default animations in SwiftUI. If your variables conform to this protocol, they will animate smoothly. For example:

```swift
struct Avatar: View {
    
    @State var selected: Bool = false
    
    var body: some View {
        Image(systemName: "heart.fill")
            .resizable()
            .foregroundStyle(.red)
            .frame(width: 48, height: 48)
            .position(x: selected ? 300 : 200, y: 200)
            .animation(.bouncy, value: selected)
            .onTapGesture {
                selected.toggle()
            }
    }
}
```

when you run this, you'll see a nice animation of the Heart Image, because the position's x and y values conform to the protocol mentioned above.

Now, let's look at another example that does not conform to this protocol:

```swift
struct MyPosition: Equatable {
  var x: CGFloat
  var y: CGFloat
}

struct MyCircle: View {
  var position: MyPosition

  var body: some View {
    GeometryReader { geo in
      Path { path in
        path.addArc(center: CGPoint(x: position.x, y: position.y),
                    radius: min(geo.size.width, geo.size.height) / 2,
                    startAngle: .zero,
                    endAngle: .degrees(360), clockwise: false)
      }
    }
  }
}

struct MyAnimatableView: View {
  @State private var position = MyPosition(x: 0, y: 0)

  var body: some View {
    MyCircle(position: position)
      .frame(width: 64, height: 64)
      .foregroundColor(.blue)
      .animation(.linear(duration: 1), value: position)
      .onTapGesture {
          position = MyPosition(x: 150, y: 0)
      }
  }
}
```

 If you run this, you will see the MyCircle View moves abruptly, and is not smooth.This happends because `MyCircle` does not conform to the `Animatable` protocol, so it cannot animate properly. If you want `MyCircle` to move more smoothly, you can add the following code:

```Swift
extension MyCircle: Animatable {
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(position.x, position.y) }
        set {
            position.x = newValue.first
            position.y = newValue.second
        }
    }
    
}
```

By adding this extension, SwiftUI will understand how to animate the position by changing the `newValue`.

The essence of the animation is that it creates multiple frames and transitions between them based on delta changes. Therefore, we need to let SwiftUI know which parameters can animate.