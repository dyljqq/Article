## Nonisolated 和 isolated关键字：理解Actor isolation

#### 省流提醒：

我们可以通过isolated和nonisolated关键字，去精准控制actor隔离域。

[原文链接:Nonisolated and isolated keywords: Understanding Actor isolation](https://www.avanderlee.com/swift/nonisolated-isolated/)



[SE-313](https://github.com/apple/swift-evolution/blob/main/proposals/0313-actor-isolation-control.md)介绍将nonisolated和isolated关键字作为actor isolation控制的一部分。Actors是一种通过新的并发框架为共享的可变状态提供同步的新方式。

如果你是刚接触Swift中的actors，那么我推荐你去阅读我的文章[swift中的actors，如何使用和阻止数据竞争](https://www.avanderlee.com/swift/actors/),这篇文章详细的介绍了它们。这篇文章将会解释当在Swift中使用actors的时候，如何通过隔离来控制方法和参数。

### 理解如何使用actors的默认行为

默认的，每个actor中的方法都是隔离的（isolated），这意味着你必须在actor中的上下文，或者使用await去等待批准访问actor中的数据。

你可以在 *[Async await in Swift explained with code examples](https://www.avanderlee.com/swift/async-await/)*中学到更多有关async/await的内容。

下面是一些典型的会产生错误的场景：

	* Actor-isolated属性*balance*不能在非隔离的上下文中被引用
	* 表达式是*async*，但是没有标记成*await*

上述的两个错误有一个核心的产生原因：actors隔离意味着我们可以保证属性之间的互斥访问。

以bank account actor为例：

```swift
actor BankAccountActor {
  enum BankError: Error {
    case insufficientFunds
  }
  
  var balance: Double
  
  init(initialDeposite: Double) {
    self.balance = initialDeposite
  }
  
  func transfer(amount: Double, to toAccount: BankAccountActor) async throws {
    guard balance >= amount else { throw BankError.insufficientFunds }
    balance -= amount
    await toAccount.deposit(amount: amount)
  }
  
  func deposit(amount: Double) {
    balance = balance + amount
  }
}
```

默认情况下，actors中的方法是被隔离的，但是它们没有显式的标记。你可能会拿它跟那些是内部的方法，但是没有显式的internal标记的关键字所修饰的方法。本质上说，它们的代码就像下面所示的那样：

```swift
isolated func transfer(amount: Double, to toAccount: BankAccountActor) async throws {
    guard balance >= amount else {
        throw BankError.insufficientFunds
    }
    balance -= amount
    await toAccount.deposit(amount: amount)
}

isolated func deposit(amount: Double) {
    balance = balance + amount
}
```

然而，显式的给方法加上isolated关键字会导致以下的错误：

​	*isolated* 只能作用于方法的参数

所以，我们只能用isolated关键字去修饰方法的参数。

### 将actor中的方法参数标记成isolated

为参数使用isolated关键字是一种非常好的方式，去用更少的代码解决特定的问题。上述的代码示例，介绍了一个deposit方法去改变另一个银行账户的余额。

我们将会通过将参数标记成isolated的方式，来去除deposit这个额外的方法，然后去直接修改另一个账户的余额：

```swift
func transfer(amount: Double, to toAccount: isolated BankAccountActor) async throws {
    guard balance >= amount else {
        throw BankError.insufficientFunds
    }
    balance -= amount
    toAccount.balance += amount
}
```

结果就是我们使用了更少的代码，来让它变得更加的可读。

多个isolated的参数是被禁止的，但是现在编译器允许我们这么做：

```swift
func transfer(amount: Double, from fromAccount: isolated BankAccountActor, to toAccount: isolated BankAccountActor) async throws {
    // ..
}
```

不过，最初的提案是不允许我们这么做的，所以在未来的Swift版本，可能会要求你去更新这段代码。

### 在actors中使用nonisolated关键字

将方法或者参数标记成nonisolated，可以选择性的退出actor中的默认隔离的机制。选择性退出可以很有效的帮助我们去使用不可变的数据，或者当符合协议要求的时候。

下面这个例子，我们将会在账户中添加一个accountHolder的变量：

```swift
actor BankAccountActor {
    
    let accountHolder: String

    // ...
}
```

accountHolder是一个不可变的变量，因此在非隔离的环境中也是可以被安全访问的。编译器足够聪明到可以分辨出这个状态，所以可以没有必要显示的去将这个变量标记成nonislated。

然而，如果我们通过计算变量去访问一个不可变的属性，我们可能需要帮助一下编译器。让我们看下如下的代码：

```swift
actor BankAccountActor {

    let accountHolder: String
    let bank: String

    var details: String {
        "Bank: \(bank) - Account holder: \(accountHolder)"
    }

    // ...
}
```

如果我们要马上输出details的数据，那么就会发生如下的错误：

​	actor-isolated中的属性不能在non-isolated上下文中被引用。

bank和accountHolder都是不可变的属性，所以我们可以显示的将计算属性标记成nonisolated，然后解决这个错误：

```swift
actor BankAccountActor {

    let accountHolder: String
    let bank: String

    nonisolated var details: String {
        "Bank: \(bank) - Account holder: \(accountHolder)"
    }

    // ...
}
```

### 用nonisolated解决协议一致性的问题

如果我们能保证访问的都是不可变的状态， 那么同样的原则适用于协议一致性。举个例子，我们可以将details的属性替换成更好的`CustomStringConvertible`协议：

```swift
extension BankAccountActor: CustomStringConvertible {
    var description: String {
        "Bank: \(bank) - Account holder: \(accountHolder)"
    }
}
```

使用Xcode推荐的默认实现，我们会运行产生如下的错误：

​	Actor-isolated属性`description`不能满足协议要求

可以使用nonisolated关键字解决上述的问题:

```swift
extension BankAccountActor: CustomStringConvertible {
    nonisolated var description: String {
        "Bank: \(bank) - Account holder: \(accountHolder)"
    }
}
```

编译器是足够聪明的，当nonisolated环境中出现isolated属性的时候，它会给我们警示!!!

### 结论

Swift中的actors是一种非常好的让我们同步访问可变状态的方式。然而，在一些例子中，我们想要控制actor的隔离状态，因为我们可以确保只访问不可变的状态。通过使用nonisolated和isolated关键字，我们可以精准控制actor隔离。

