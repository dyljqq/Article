如何使用async/await进行并发编程。

这是我在开发过程中碰到的一个case：

现在有一个Git Repo的界面，我需要获取三个接口的数据，分别是：

	* 获取Repo的信息
	* 获取README信息
	* 是否已经给这个Repo标星

这三个操作互相没有依赖，那么常规的做法的话，我们只需要使用GCD，即：

```swift
DispatchQueue.global().async {
  // 获取Repo
   self.fetchRepo()
}

DispatchQueue.global().async {
  // 是否标星
   self.configStarButton()
}

DispatchQueue.global().async {
  // 获取README
  RepoViewModel.fetchREADME(with: self.repoName)
}
```

但是我们现在需要通过Async对这个项目进行改写，可能我们会写成：

```swift
Task {
	await self.fetchRepo()
  await self.configStarButton()
  await RepoViewModel.fetchREADME(with: self.repoName)
}
```

但是上述的方式的话，其实还是串行执行的，异步的本质就是通过await来标记一个暂停的点，然后让他不至于阻塞线程，底层会给他分配一个合适的线程，执行完之后，再返回到原来标记为暂停的点，接着往下执行。但是这样显然不是我们想要的结果，我们期望看到的是，这三个方法是并发执行的。因此，我们可以做如下的改动：

```swift
Task {
    await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        await self.fetchRepo()
      }
      group.addTask {
        await self.configStarButton()
      }
      group.addTask {
        Task {
          if let readme = await RepoViewModel.fetchREADME(with: self.repoName) {
            await self.footerView.render(with: readme.content)
          }
        }
      }
    }
  }
```

我们通过引入task group的方式去管理这个并发。又或者我们可以通过async let来执行：

```swift
async let fetchRepo = await self.fetchRepo()
async let configStarButton = await self.configStarButton()
async let readme = await RepoViewModel.fetchREADME(with: self.repoName)
```

