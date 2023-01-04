在执行如下指令时报错：

```shell
git push origin dev
```

报如下错误：

```
git remote: Support for password authentication was removed on August 13, 2021
```

大致意思就是说，git在2021.8.13日就不能通过密码做权限校正了。

去网上搜了一些解决方案，目前对我自己有效的其实是通过在github上申请[Personal Auth Token](https://github.com/settings/tokens)，然后执行如下代码：

```
git remote set-url origin https://<github token>@github.com/<username>/<reponame>.git
```

参考文章: [How to fix support for password authentication was removed on GitHub](https://levelup.gitconnected.com/fix-password-authentication-github-3395e579ce74)

