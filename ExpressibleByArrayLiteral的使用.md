首先我们先来看一个例子：

	enum LinkList<Element> {
	    case end
	    indirect case node(Element, next: LinkList<Element>)
	}
	
	extension LinkList {
		@discardableResult
	    func cons(_ element: Element) -> Self {
	        return .node(element, next: self)
	    }
    }
	
这个时候，我们如果要构造一个链表，要怎么做呢？

	let node = LinkList.end.cons(2).cons(3).cons(4)
	
这种链式结构虽然看起来还行，也很直观，但是！如果我们要构造一个100个元素的链表，要这样做一百次么？显然这不是一个很棒的选择。因此，我们可以用一种更加棒的方法。我们都知道，在Swift中，数组的定义可以简单的写为:

	let nums = [1, 2, 3]
	
那么为什么数组可以这么写呢，因为他遵守了一个协议，这个协议就是：

	public protocol ExpressibleByArrayLiteral {
	  /// The type of the elements of an array literal.
	  associatedtype ArrayLiteralElement
	  /// Creates an instance initialized with the given elements.
	  init(arrayLiteral elements: ArrayLiteralElement...)
	}
	
	extension Array: ExpressibleByArrayLiteral {
	  // Optimized implementation for Array
	  /// Creates an array from the given array literal.
	  ///
	  /// Do not call this initializer directly. It is used by the compiler
	  /// when you use an array literal. Instead, create a new array by using an
	  /// array literal as its value. To do this, enclose a comma-separated list of
	  /// values in square brackets.
	  ///
	  /// Here, an array of strings is created from an array literal holding
	  /// only strings.
	  ///
	  ///     let ingredients = ["cocoa beans", "sugar", "cocoa butter", "salt"]
	  ///
	  /// - Parameter elements: A variadic list of elements of the new array.
	  @inlinable
	  public init(arrayLiteral elements: Element...) {
	    self = elements
	  }
	}
	
因此，我们是不是也可以用这种方式来构建一个链表呢？答案当然是可以的，具体实现如下:

	extension LinkList: ExpressibleByArrayLiteral {
    
    init(arrayLiteral elements: Element...) {
	        self = elements.reversed().reduce(.end) { linkList, element in
	            linkList.cons(element)
	        }
	    }
	}

然后我们在使用的时候，只需要:

	let linkList: LinkList = [1,2,3]
	
就可以了。是不是比上面的实现，要更加的方便更简洁呢。