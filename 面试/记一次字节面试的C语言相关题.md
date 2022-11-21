前言，因为工作比较久了，工作中碰到的大多都是一些高级语言相关的工作，比如Swift。很少会涉及一些编译，链接相关的知识。所以这个时候，字节的面试官就考了我一些比较基础的C语言相关的题目。这里做一下记录吧。



### 首先是一道关于extern相关的题。

```c
// hello.c

int hello = 1;

// source.c

int hello = 2;

// main.c
extern int hello;

int main() {
  printf("hello: %d", hello);
}
```

问上面这样写会不会碰到什么问题。根据经验来说的话，main.c中的hello一定是通过外部符号导入的，因此如果对这三个文件进行编译连接的话，就会报错。

```
gcc hello.c source.c  main.c -o main

报错：
duplicate symbol '_hello' in:
    /var/folders/jb/6wwphjfn3mv8ct94nmxlzk4r0000gn/T/hello-87d9c2.o
    /var/folders/jb/6wwphjfn3mv8ct94nmxlzk4r0000gn/T/source-14e887.o
ld: 1 duplicate symbol for architecture arm64
clang: error: linker command failed with exit code 1 (use -v to see invocation)


跟自己预想的是一样的。因为之前没有做过实验，所以也还是以比较不是很确定的语气说出。
```

然后面试官问是在什么阶段产生的。因为根据编译跟链接的原理来看的话，只有当程序在链接的时候，才会去找文件中缺失的符号。这里的符号就是hello。然后因为两个文件，hello.c，source.c都有对应的符号，机器是无法判断到底链接哪一个，因此报了一个duplicate symbol '_hello'的错误，把问题抛给了开发者。



紧接着。面试官问，如果把中间一个文件的 int hello = 2;改成static int hello = 2;会不会有问题。我的理解是不会有的，因为他们的修饰符已经变了，链接的时候链接器也不会有疑惑，到底应该取哪个文件的hello。

虽然说出了答案，但是还是不是非常确定，因此记录与实践了一下。

后面也会更在关注编译，链接相关的知识，把以前的东西捡起来吧。

### 一道内存题。