我们之前有解释过，SwiftUI中，有`public protocol Layout : Animatable`，我们可以通过这个协议来自定义。

其实，我们在`UIKit`中如何定义三个拥有同等宽度的按钮呢？我们的思路会是：

1. 获取每个Button中的文案
2. 然后计算出这个字体下，这些文案的宽度
3. 缓存最大的按钮宽度，然后赋予其他的按钮，并设定为他们的宽。

但是，到了SwiftUI的话，我们只需要自定义`Layout`，然后在里面去实现我们的规则。具体思路如下：

1. 获取每个子视图的宽度，然后得到最宽的子视图的大小。
2. 当然我们还需要获取每个子视图之间的spacing。
3. 最后通过`placeSubviews`, 将所有的子视图的size都替换为最大的button。

代码如下:

```swift
struct MyEqualWidthHStack: Layout {
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxSize = self.maxSize(from: subviews)
        let totalSpacing = spacing(by: subviews).reduce(0) { $0 + $1 }
        return CGSize(
            width: maxSize.width * CGFloat(subviews.count) + totalSpacing,
            height: maxSize.height
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxSize = self.maxSize(from: subviews)
        let spacings = self.spacing(by: subviews)
        
        let placementProposal = ProposedViewSize(width: maxSize.width, height: maxSize.height)
        var x: CGFloat = bounds.minX + maxSize.width / 2
        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(x: x, y: bounds.minY),
                anchor: .center,
                proposal: placementProposal
            )
            x += maxSize.width + spacings[index]
        }
    }
    
}

extension MyEqualWidthHStack {

    func maxSize(from subviews: Subviews) -> CGSize {
        let subViewSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return subViewSizes.reduce(CGSize.zero) { currentMax, subViewSize in
            return CGSize(
                width: max(currentMax.width, subViewSize.width),
                height: max(currentMax.height, subViewSize.height)
            )
        }
    }
    
    func spacing(by subviews: Subviews) -> [CGFloat] {
        subviews.indices.compactMap { index in
            guard index < subviews.count - 1 else { return 0 }
            return subviews[index].spacing.distance(to: subviews[index + 1].spacing, along: .horizontal)
        }
    }
    
}
```

值得一提的是，当我们调用如上的`MyEqualWidthHStack`的时候，会发现不生效，如下:

```swift
import SwiftUI

struct ButtonStack: View {
    
    let titles = ["Cat", "Goldfish", "Dog"]
    
    var body: some View {
        MyEqualWidthHStack {
            ForEach(titles.indices, id: \.self) { index in
                Button {
                    
                } label: {
                    Text(titles[index])
                        // .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
```

当注释掉`.frame(maxWidth: .infinity)`modifier的时候，我们会发现button还是按照文本内容进行填充的。这个是因为，如果我们不设定frame的话，SwiftUI会进行默认布局，即按照内容进行填充。只有设定了frame之后，SwiftUI才会真的按照我们的自定义Layout进行布局。

如果有理解不到位的地方，欢迎解答。