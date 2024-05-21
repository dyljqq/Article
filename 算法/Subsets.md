### 如何获取一个数组的子数组的集合

[78. Subsets](https://leetcode.com/problems/subsets/)

```swift
func subsets(_ nums: [Int]) -> [[Int]] {
      nums.reduce([[]]) { (result, num) in
          return result + result.map { $0 + [num] }
      }
  }
```

太简洁，太优雅了。