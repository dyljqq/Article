import Cocoa

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
