# 如何修复protocol can only be used as a generic constraint because it has Self or associated type requirements错误

在协议中使用associatedtype类型是非常强大的，但是你有时候会碰到下面这个问题，protocol can only be used as a generic constraint because it has Self or associated type requirements.我们举个例子：

```swift
protocol Identifiable {
    associatedtype ID
    var id: ID { get set }
}

struct Person: Identifiable {
    var id: String
}

struct Website: Identifiable {
    var id: URL
}
```

通过上面的代码我们知道，ID在person中是String类型，在Website中是URL类型。

然后我们定义一个函数，来接收两个Identifiable协议的参数。

```swift
func compareThing1(_ thing1: Identifiable, against thing2: Identifiable) -> Bool {
    return true
}
```

这时候，会出现编译错误，即protocol can only be used as a generic constraint because it has Self or associated type requirements.

从这个报错，我们知道，是编译器无法判定thing1根thing2的ID类型，我们并没有明确给出。因此我们需要一种方法来避免这个情况。我们只需要定义一个范型，并且这个类型是遵循Identifiable协议的，那么就可以避免这个错误，这应该也叫做类型擦除。

```swift
func compareThing1<T: Identifiable>(_ thing1: T, against thing2: T) -> Bool {
    return true
}
```

然后Swift可以自己根据类型推断，来知道thing1是Person类型还是Website类型。