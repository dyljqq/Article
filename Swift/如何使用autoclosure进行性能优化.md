# 如何使用@autoclosure进行性能优化

首先我们需要明确什么是autoclosure，其实就像它所表达的意思一样，就是通过这个关键字，我们可以自动把一个参数转化为函数！

接下来我们来看下，如何通过这个进行优化。先举个简单的例子，如果我们要实现一个||(或)运算符，那么我们可以这样写：

```swift
func ||(left: Bool, right: Bool) -> Bool {
    if left {
        return left
    } else {
        return right
    }
}
```

很简单的一个函数，如果left为true，那么直接返回left，否者返回right。那么问题来了，如果right的判定是一个非常复杂的函数呢，而left是false，那岂不是白白做了一次right的判定计算操作？很明显这里是可以优化的，那么我们可以进行这样改动：

```swift
let right = {
    return true
}

func ||(left: Bool, right: @autoclosure () -> Bool) -> Bool {
    if left {
        return left
    } else {
        return right()
    }
}
```

这样，就可以做到延迟计算，提高性能。

[How to use @autoclosure in Swift to improve performance](https://www.avanderlee.com/swift/autoclosure/)

这篇文章提供了一个比较好的例子如下：

```swift
struct Person: CustomStringConvertible {
     let name: String
     
     var description: String {
         print("Asking for Person description.")
         return "Person name is \(name)"
     }
 }

 let isDebuggingEnabled: Bool = false
 
 func debugLog(_ message: String) {
     /// You could replace this in projects with #if DEBUG
     if isDebuggingEnabled {
         print("[DEBUG] \(message)")
     }
 }

 let person = Person(name: "Bernie")
 debugLog(person.description)
```

上面的代码说，当isDebuggingEnabled开启的时候，我们去打印person的description。但是在正常的情况是，当我们执行debugLog(person.description)时，person.description已经计算了对应的值，而不会去关心isDebuggingEnabled是否为true，这样就有违我们的本意。因此我们可以通过@autoclosure去改写，如下：

```swift
 let isDebuggingEnabled: Bool = false
 
 func debugLog(_ message: @autoclosure () -> String) {
     /// You could replace this in projects with #if DEBUG
     if isDebuggingEnabled {
         print("[DEBUG] \(message())")
     }
 }

 let person = Person(name: "Bernie")
 debugLog(person.description)
```

这样，只有在isDebuggingEnabled为true的时候，我们才会去调用person.description。
