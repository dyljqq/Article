### 前言

其实我就是想吐槽一下，SQLite是真的难用啊，刚接触的时候，各种诡异的bug，配合诡异的状态码。

但是其实，就简单的增删改查来说，也并不复杂，我自己封装了一个数据管理的类，配合SQLTable的协议，能够比较方便的对model做存储的工作。具体如下:

[SQLite封装代码](https://github.com/dyljqq/DJReader/tree/master/DJReader/Vendor/Database)

其实我觉得所有的数据库操作都是，先打开数据库，然后根据输入的sql，最后处理结果。
	