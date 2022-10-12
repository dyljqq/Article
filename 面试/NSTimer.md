## NSTimer循环引用&精度不准

循环引用主要是因为构造方法中的target会强引用self。

解决办法的话：

* NSProxy
* Block
* 单独构造一个包含NSTimer的类
* 在合适的地方invalid NSTimer

精度不准的问题是因为runloop会在创建timer的时候，标记这个点，然后每次runloop会按时处理这个事件，当这个点的事件超时的时候，则会跳过。

* CASDisplayLink
* GCD dispatch_source