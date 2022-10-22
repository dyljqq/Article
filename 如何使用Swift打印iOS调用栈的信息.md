## 如何使用Swift打印iOS调用栈的信息

首先我们要清楚，每个线程都有自己的栈空间，里面会有很多函数调用。我们以arm64为例，他的结构是这样的：

```
Stack frame structure for arm/arm64:
 *
 *    | ...                   |
 *    +-----------------------+ hi-addr     ------------------------
 *    | func0 lr              |
 *    +-----------------------+
 *    | func0 fp              |--------|     stack frame of func1
 *    +-----------------------+        v
 *    | saved registers       |  fp <- sp
 *    +-----------------------+   |
 *    | local variables...    |   |
 *    +-----------------------+   |
 *    | func2 args            |   |
 *    +-----------------------+   |         ------------------------
 *    | func1 lr              |   |
 *    +-----------------------+   |
 *    | func1 fp              |<--+          stack frame of func2
 *    +-----------------------+
 *    | ...                   |
 *    +-----------------------+ lo-addr     ------------------------
```

因此，我们只要知道知道线程的栈基址，就可以获取到fp，然后通过不断的递归调用，就可以获取到所有的线程调用函数地址了。然后通过swift中的dl_info结构分析出这个地址的函数名等信息。

```swift
public struct dl_info {

    public init()

    public init(dli_fname: UnsafePointer<CChar>!, dli_fbase: UnsafeMutableRawPointer!, dli_sname: UnsafePointer<CChar>!, dli_saddr: UnsafeMutableRawPointer!)

    public var dli_fname: UnsafePointer<CChar>! /* Pathname of shared object */

    public var dli_fbase: UnsafeMutableRawPointer! /* Base address of shared object */

    public var dli_sname: UnsafePointer<CChar>! /* Name of nearest symbol */

    public var dli_saddr: UnsafeMutableRawPointer! /* Address of nearest symbol */
}
```

这样就能获取到线程的函数调用情况了。