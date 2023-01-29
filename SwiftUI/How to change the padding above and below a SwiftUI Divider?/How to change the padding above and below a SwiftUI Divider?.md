例如如下的代码，我们构造了一个列表，并在每个Item下面添加一个Divider()的视图：

```swift
ScrollView {
    LazyVStack {
        ForEach(feeds, id: \.id) { feed in
            VStack {
                Text(feed.title)
                Divider()
            }
        }
    }
}
```

如上图代码所示，divider上下都会有大概10dp左右的间距。

但是其实这个间距并不是Divider()所产生的，而是由VStack所生成的，VStack会默认给子view添加一个默认的spacing，因此，我们只需要这样，就可以取消上下的间距:

```swift
ScrollView {
    LazyVStack(spacing: 0) {
        ForEach(0..<10) { id in
            VStack(alignment: .leading, spacing: 0) {
                Text("id: \(id)")
                Divider()
            }
            .padding(.leading, 16)
        }
    }
}
```

