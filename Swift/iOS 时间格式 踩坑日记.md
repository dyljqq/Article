首先说一下之前的实现方案:

```swift
let defaultFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = Date.is24Hours ? "yyyy-MM-dd HH:mm:ss" : "yyyy-MM-dd hh:mm:ss"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()
```

但是上述的方案，针对部分手机，会出现解析失败的情况。

比如如果你的字符串中，小时超过12，如`2024-12-06 23:59:59`,那么部分手机按照上述的格式，就会解析失败。但是针对小时小于12的，可以正常解析，如`2024-12-06 11:59:59`。

那么如何解决呢？

其实把判断是否采用24小时制的限制去掉，直接使用：

```swift
formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" 
```

那么`HH`就可以覆盖所有的时间格式情况。