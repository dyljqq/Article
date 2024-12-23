# any & some

### any关键字

##### 目的

any关键字用于定义已存在的类型，意味着，一个遵循这个协议的类型，但是具体的类型会被隐藏。这在你想要使用任何一个遵循这个协议，但是又不关心他的具体类型的时候，any会显得非常有用。



##### 举个例子：

```swift
protocol Drawable {
    func draw()
}

func render(shape: any Drawable) {
    shape.draw()
}

let circle = Circle()  // Circle 遵循 Drawable
render(shape: circle)  // 适用于符合 Drawable 协议的任意类型。
```

##### 关键特性

* 类型擦除：具体类型没有被保留。你只知道它遵循这个协议。
* 动态派发：对协议方法的调用是动态派发的。
* 使用例子：当你需要灵活性，并且不需要编译器跟踪具体类型的时候。



### some关键字

##### 目的

some关键字用于定义透明类型，意味着，一个遵循这个协议的特定类型，但是他的身份是对调用者隐藏的。当你需要返回一个单一，特定的复合一个协议的具体类型，但是你又不想在函数签名中暴露这个具体的类型，那么这个时候，some关键字会非常有用。



##### 举个例子：

```swift
protocol Drawable {
    func draw()
}

struct Circle: Drawable {
    func draw() {
        print("Drawing a circle")
    }
}

func createCircle() -> some Drawable {
    return Circle()
}

let shape = createCircle()
shape.draw()
```



##### 关键特性

* 类型保留：底层类型在内部被保留，但是对调用者隐藏
* 静态派发：方法的调用是静态派发，提升了性能
* 使用例子：当你需要类型安全，同时又想抽象实现细节。