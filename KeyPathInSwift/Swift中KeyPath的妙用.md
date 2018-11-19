# KeyPath在Swift中的妙用

[原文链接: The power of key paths in Swift](https://www.swiftbysundell.com/posts/the-power-of-key-paths-in-swift)

自从swift刚开始就被设计为是编译时安全和静态类型后，它就缺少了那种我么经常在运行时语言中的动态特性，比如Object-C, Ruby和JavaScript。举个例子，在Object-C中，我们可以很轻易的动态去获取一个对象的任意属性和方法 - 甚至可以在运行时交换他们的实现。

虽然缺乏动态性正是Swift如此强大的一个重要原因 - 它帮助我们编写更加可以预测的代码以及更大的保证了代码编写的准确性, 但是有的时候，能够编写具有动态特性的代码是非常有用的。

值得庆幸的是，Swift不断获取越来越多的更具动态性的功能，同时还一直把它的关注点放在代码的类型安全上。其中的一个特性就是KeyPath。这周，就让我们来看看KeyPath是如何在Swift中工作的，并且有哪些非常酷非常有用的事情可以让我们去做。

### 基础知识

Key paths实质上可以让我们将任意一个属性当做一个独立的值。因此，它们可以传递，可以在表达式中使用，启用一段代码去获取或者设置一个属性，而不用确切地知道它们使用哪个属性。

Key paths主要有三种变体:

* KeyPath: 提供对属性的只读访问
* WritableKeyPath: 提供对具有价值语义的可变属性提供可读可写的访问
* ReferenceWritableKeyPath: 只能对引用类型使用(比如一个类的实例), 对任意可变属性提供可读可写的访问

这里有一些额外的keypath类型，它们可以减少内部重复的代码，以及可以帮助我们做类型的擦除，但是我们在这篇文章中，会专注于上面的三种主要的类型。

让我们深入了解如何使用key paths吧，以及使它们变得有趣且非常强大的原因。

### 功能速记

我们这样说吧，我们正在构建一个可以让我们阅读从网络上获取到文章的app，以及我们已经有一个Article的模型用来表达这篇文章，就像下面这样:

	struct Article {
	    let id: UUID
	    let source: URL
	    let title: String
	    let body: String
	}
	
无论什么时候，我们使用这个模型数组，通常需要从每个模型中提取单个数据以组成新的数组 - 就像下面这两个从文章数组中获取所有的IDs和sources的列子一样:

	let articleIDs = articles.map { $0.id }
	let articleSources = articles.map { $0.source }
	
虽然上面的实现完全没有问题，但是我们只是想要从每个元素中提取单一的值，我们不是真的需要闭包的所有功能 - 所以使用keypath就可能非常合适。让我们看看它是如何工作的吧。

我们会通过在Sequence协议中重写map方法来处理key path，而不是通过闭包。既然我们只对这个使用例子的只读访问有兴趣，那么我们将会使用标准的KeyPath类型，并且为了实际的数据提取，我们将会使用给定的键值路径作为下标参数，如下所示：

	extension Sequence {
		func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
		  return map { $0[keyPath: keyPath] }
		}
	}
	
随着上述准备就绪，我们能够使用友好和简单的语法来从任意的序列元素中提取出单一的值，使将之前的列子转化成下面的样子成为可能：

	let articleIDs = articles.map(\.id)
	let articleSources = articles.map(\.source)
	
这是非常酷的，但是键值路径真正开始闪光的时候，是当它们被用来组成更加灵活的表达式 - 比如当给序列的值排序的时候。

标准库可以给任意的包含可排序的元素的序列进行自动排序，但是对于其他不可排序的元素，我们必须提供自己的排序闭包。然而，使用键值对，我们可以很简单的给任意的可比较的元素添加排序的支持。就像之前一样，我们给序列添加一个扩展，来将给定的键值对在排序表达闭包中进行转化:

	extension Sequence {
	    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
	        return sorted { a, b in
	            return a[keyPath: keyPath] < b[keyPath: keyPath]
	        }
	    }
	}
	
使用上述方法，我们可以非常快速的排序任意的序列，只用简单的提供一个我们期望被排序的键值对。如果我们构建的app是用来处理任意的可排序的列表 - 举个例子，一个包含了播放列表的音乐app - 这将是非常有用的，我们现在可以随意排序基于可比较属性的列表（甚至是嵌套的属性）。

	playlist.songs.sorted(by: \.name)
	playlist.songs.sorted(by: \.dateAdded)
	playlist.songs.sorted(by: \.ratings.worldWide)

完成上述的事情看起来有点简单，就像添加了一个语法糖。但是既可以写出更加灵活的代码去处理序列，让他们更易读，也可以减少重复的代码。因此我们现在能够为任意属性重用相同的排序代码。