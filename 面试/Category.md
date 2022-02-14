# Category源码分析

Category也叫分类，主要作用就是为已经存在的类添加方法。比如我们可以给系统类添加扩展，而不用修改源码。

下面是一个比较简单的栗子：

```
首先我定义了一个Son类，这个类可以输出自己的名字.

@interface Son : NSObject

- (void)printName;

@end

@implementation Son

- (void)printName {
    NSLog(@"Son");
}

@end

这个时候，我们为Son添加了一个分类，这个分类的作用也是输出名字，如下：

@interface Son (Jack)

- (void)printName;

@end

@implementation Son (Jack)

- (void)printName {
    NSLog(@"Jack");
}

@end

那么这个时候，如果我们实例化一个Son，如：

Son *son = [Son new];
[son printName];

会输出什么结果呢？是Son还是Jack呢？这个时候我们一定会感动困惑，这个需要我们了解程序中实例化的方法的加载顺序。从源码中我们可以看出，首先系统会加载他的父类，然后加载该类，然后加载对应的分类。这些方法都被存在一个名叫const struct _method_list_t *instance_methods;的数据结构中，然后会通过：
addUnattachedCategoryForClass(cat, cls, hi);
方法将分类中的方法给添加到类中，而这个时候，它是插入到方法的前面的，因此在进行消息传递的时候，会优先调用分类中的同名方法，在消息传递链中我们知道，一旦找到对应的方法之后，就会返回，因此即使有多个同名的方法，也只会取最前面且有效的方法。

那么如果这个时候，又出现一个分类叫做Andy，且同样有对应的printName方法的话，那么会输出什么结果呢？

@interface Son (Andy)

- (void)printName;

@end

@implementation Son (Andy)

- (void)printName {
    NSLog(@"Andy");
}

@end

结论就是会随机出现Andy跟Jack，这一切其实都要看分类文件的加载顺序。会输出后面加载的分类的结果，道理如上，因为最后加载的，方法会在前面。

```

还有一个比较常问的问题，那就是分类中会有实例变量么，我们知道在OC中，实例变量是存在ivars数组中的，且在编译的时候，就已经确定了。对于分类这种运行时的结构来说，应该是没有的，因为我们无法改变已经存在的东西。而事实也是这样，我们看到分类编译后的结构如下：

```
struct _category_t {
	const char *name;
	struct _class_t *cls;
	const struct _method_list_t *instance_methods;
	const struct _method_list_t *class_methods;
	const struct _protocol_list_t *protocols;
	const struct _prop_list_t *properties;
};

从这里可以看出，确实不存在ivars变量，而从这个结果中我们可以看到，我们可以在分类中，定义实例方法，类方法，协议以及属性，但是这个属性不是我们认识的那种，它只是会生成对应的get跟set方法，但是却并没有实现，我们可以通过关联属性来做属性方法的填充，这个又是后话了。


```