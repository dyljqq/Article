### defer的使用原理

```c++
#ifndef SWIFT_BASIC_DEFER_H
#define SWIFT_BASIC_DEFER_H

#include "llvm/ADT/ScopeExit.h"

namespace swift {
  namespace detail {
    struct DeferTask {};
    template<typename F>
    auto operator+(DeferTask, F &&fn) ->
        decltype(llvm::make_scope_exit(std::forward<F>(fn))) {
      return llvm::make_scope_exit(std::forward<F>(fn));
    }
  }
} // end namespace swift


#define DEFER_CONCAT_IMPL(x, y) x##y
#define DEFER_MACRO_CONCAT(x, y) DEFER_CONCAT_IMPL(x, y)

/// This macro is used to register a function / lambda to be run on exit from a
/// scope.  Its typical use looks like:
///
///   SWIFT_DEFER {
///     stuff
///   };
///
#define SWIFT_DEFER                                                            \
  auto DEFER_MACRO_CONCAT(defer_func, __COUNTER__) =                           \
      ::swift::detail::DeferTask() + [&]()

#endif // SWIFT_BASIC_DEFER_H
```

上述的代码是defer在Swift源码中的声明与实现。我们可以很直观的看到，底层是通过C++实现的。我们可以把defer声明的闭包，看作是一个函数内的变量，那么根据C++的局部变量的生命周期规则, 也就是LIFO（Last In First Out），最后被声明的defer的闭包，是最开始被释放的，所以会最先被执行。

之前面试字节的时候，就被问到过defer相关的问题，比如生命周期，释放的的顺序，以及看过源码么？知道他的底层实现么？举个例子：

```swift
func test() {
    defer { print("1") }
    defer { print("2") }
    print("3")
  	defer{
    	print(4)
  	}
}
```

输出的结果为：

3

4

1

2

跟我们的预期相符合。



### defer的使用场景

实际开发的项目中，我们在使用数据库的时候，会需要在打开完数据库后，执行关闭的操作。但是，这中间可能会有非常多的if，guard等逻辑判断的操作，这个时候，如果按照逻辑线去找函数执行结束的话，难免会有遗漏，此时的defer就会是一个非常好的选择。

又比如`UIGraphicsBeginImageContextWithOptions(imgSize, **false**, 0)`, 我们会需要在绘制结束后，执行`UIGraphicsEndImageContext()`来关闭图形上下文

```swift
UIGraphicsBeginImageContextWithOptions(imgSize, false, 0)
defer {
    /// 5. 关闭图形上下文
    UIGraphicsEndImageContext()
}
 // TODO something
```

