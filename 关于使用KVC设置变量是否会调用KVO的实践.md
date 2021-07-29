# 关于使用KVC设置变量是否会调用KVO的实践

首先我们要得出结论，就是会调用。至于为什么呢？最开始我理解就是KVC会通过key值，把value赋给相应的对象，可能只是一个简单的hash操作。但其实看了源码，我们摘取比较主要的来看：

比如我有一个Son类型,有个属性值，叫text，那么我们通过KVC去赋值:

	[son setValue: @"123", forKey: @"text"];

过滤一下就是:

	- (void) setValue: (id)anObject forKey: (NSString*)aKey {
		.....
	 	SetValueForKey(self, anObject, key, size);
	}
	
	static void
	SetValueForKey(NSObject *self, id anObject, const char *key, unsigned size) {
		// 前面获取到合适的key，可能是setKey, _setKey等
		重点调用了：
		
		sel = sel_getUid(key);
		GSObjCSetVal(self, key, anObject, sel, type, size, off);
	}
	
	// 然后重点来了，在GSObjCSetVal内部，因为setText的类型是：v24@0:8@16，对应#define _C_VOID     'v'
	
	void        (*imp)(id, SEL) =
                (void (*)(id, SEL))[self methodForSelector: sel];

              (*imp)(self, sel);
              
           
所以本质上，还是会执行setText的方法，转化一下就是 [son setText: @"123"];

这里通过实验我们知道，imp是_NSSetObjectValueAndNotify类型了，而son其实已经被苹果内部重写，isa指向了新建的类NSKVONotifying_Son中。

因此，我们可以说，通过KVC赋值的方式会触发KVO;