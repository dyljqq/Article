### actor 是线程安全的么？

[The Actor Reentrancy Problem in Swift](https://swiftsenpai.com/swift/actor-reentrancy-problem/)

不是的。考虑reentrance的情况

suspension point是否在actor里，如果有的话，那么在并发的两个task，就有可能会发生`重入(Reentrance)`的情况。

举个例子：

```swift
actor BankAccount {
    
    private var balance = 1000
    
    func withdraw(_ amount: Int) async {
        
        print("🤓 Check balance for withdrawal: \(amount)")
        
        guard canWithdraw(amount) else {
            print("🚫 Not enough balance to withdraw: \(amount)")
            return
        }
        
        guard await authorizeTransaction() else {
            return
        }
        
        print("✅ Transaction authorized: \(amount)")
        
        balance -= amount
        
        print("💰 Account balance: \(balance)")
    }
    
    private func canWithdraw(_ amount: Int) -> Bool {
        return amount <= balance
    }
    
    private func authorizeTransaction() async -> Bool {
        
        // Wait for 1 second
        try? await Task.sleep(nanoseconds: 1 * 1000000000)
        
        return true
    }
}

let account = BankAccount()

Task {
    await account.withdraw(800)
}

Task {
    await account.withdraw(500)
}
```

我们可以想象一下，这个会输出什么结果？3，2，1

乍一看，我们会想，先执行完`await account.withdraw(800)`，然后剩余200，然后执行`await account.withdraw(500)`，发现余额不足，不执行。

但是结果如下：

```
🤓 Check balance for withdrawal: 800
🤓 Check balance for withdrawal: 500
✅ Transaction authorized: 800
💰 Account balance: 200
✅ Transaction authorized: 500
💰 Account balance: -300
```

你看，余额变成了-300，这明显与我们的认知不符合。那么为什么会出现的结果呢，其实是因为，actor只是能保证不出现数据竞争，但是我们的`withdraw`方法都会在`authorizeTransaction`挂起，那么也就是意味着，我们并没有在一个task执行完，才去执行另一个。也就是说，它并不会去判断挂起的时候，可变的状态还是保持你刚进入task的状态，可能有点拗口，那拿这个例子举例，就是actor不会保证，balance会自动修改为task1执行完后的值，也就是200。所以我们在做`balance -= amount`操作的时候，需要再判断一下，余额是否满足条件，这也是apple建议我们做的，即始终保持actor的状态变更是同步的。

即:

```swift
func withdraw(_ amount: Int) async {
    
    // Perform authorization before check balance
    guard await authorizeTransaction() else {
        return
    }
    print("✅ Transaction authorized: \(amount)")
    
    print("🤓 Check balance for withdrawal: \(amount)")
    guard canWithdraw(amount) else {
        print("🚫 Not enough balance to withdraw: \(amount)")
        return
    }
    
    balance -= amount
    
    print("💰 Account balance: \(balance)")
    
}
```

但是，假设`authorizeTransaction`方法非常耗时，而余额很明显是不满足扣款条件的，就是一种资源的浪费。所以我们可以：

```swift
func withdraw(_ amount: Int) async {
    
    print("🤓 Check balance for withdrawal: \(amount)")
    guard canWithdraw(amount) else {
        print("🚫 Not enough balance to withdraw: \(amount)")
        return
    }
    
    guard await authorizeTransaction() else {
        return
    }
    print("✅ Transaction authorized: \(amount)")
    
    // Check balance again after the authorization process
    guard canWithdraw(amount) else {
        print("⛔️ Not enough balance to withdraw: \(amount) (authorized)")
        return
    }

    balance -= amount
    
    print("💰 Account balance: \(balance)")
    
}
```

虽然多做了一次`canWithdraw`,但是可以提升效率，且避免了重入的问题。
