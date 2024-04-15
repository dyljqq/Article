### actor 是线程安全的么？

不是的。考虑reentrance的情况

suspension point是否在actor里，如果有的话，那么在并发的两个task，就有可能会发生`重入(Reentrance)`的情况。

