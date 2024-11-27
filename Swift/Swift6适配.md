### Swift 6的适配

##### 问题

`Cannot access property 'link' with a non-sendable type 'CADisplayLink?' from nonisolated deinit;`

解决方案：

```swift
DispatchQueue.main.async {
    self.link?.invalidate()
}
```





