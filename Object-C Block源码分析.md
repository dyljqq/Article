首先我们看一个最简单的Block的实现代码:

	void blockMain() {
	    void(^MyBlock)(void) =  ^{
	            printf("block test");
	        };
	    MyBlock();
	}
	
通过clang -rewrite-objc block.c后会得到一个block.cpp的文件，里面就是转换后的代码:

	struct __blockMain_block_impl_0 {
	  struct __block_impl impl;
	  struct __blockMain_block_desc_0* Desc;
	  __blockMain_block_impl_0(void *fp, struct __blockMain_block_desc_0 *desc, int flags=0) {
	    impl.isa = &_NSConcreteStackBlock;
	    impl.Flags = flags;
	    impl.FuncPtr = fp;
	    Desc = desc;
	  }
	};
	
我们可以看到，转换后的block __blockMain_block_impl_0 = 函数名 + block_impl + block的顺序,里面有两个变量，变量的类型为两个结构体，如下:

	struct __block_impl {
	  void *isa; // block指向block所属的类型（_NSConcreteGlobalBlock, _NSConcreteStackBlock, _NSConcreteMallocBlock）
	  int Flags; 
	  int Reserved;
	  void *FuncPtr; // 回调的函数指针
	};
	
	static struct __blockMain_block_desc_0 {
	  size_t reserved;
	  size_t Block_size;
	} __blockMain_block_desc_0_DATA = { 0, sizeof(struct __blockMain_block_impl_0)};
	
最后看blockMain：

	static void __blockMain_block_func_0(struct __blockMain_block_impl_0 *__cself) {

            printf("block test");
        }

	void blockMain() {

	    void(*MyBlock)(void) = ((void (*)())&__blockMain_block_impl_0((void *)__blockMain_block_func_0, &__blockMain_block_desc_0_DATA));
	    ((void (*)(__block_impl *))((__block_impl *)MyBlock)->FuncPtr)((__block_impl *)MyBlock);

	}
	
	
### Block带参数

	struct __blockMain_block_impl_0 {
	  struct __block_impl impl;
	  struct __blockMain_block_desc_0* Desc;
	  int a;
	  int b;
	  __blockMain_block_impl_0(void *fp, struct __blockMain_block_desc_0 *desc, int _a, int _b, int flags=0) : a(_a), b(_b) {
	    impl.isa = &_NSConcreteStackBlock;
	    impl.Flags = flags;
	    impl.FuncPtr = fp;
	    Desc = desc;
	  }
	};
	static void __blockMain_block_func_0(struct __blockMain_block_impl_0 *__cself) {
	// __cself指向block的指针
	  int a = __cself->a; // bound by copy
	  int b = __cself->b; // bound by copy
	
	        int c = a + b;
	        printf("%d", c);
	    }
	    
首先，C++中，函数名后面带上冒号是它特有的赋值方式，所以，: a(_a), b(_b)表示给a与b赋值。与不带参数的block相比，带参数的block其实也就是多了几个参数，即对参数进行了复制。


### __block修饰符

添加__block修饰符的变量，在编译后会多出：

	struct __Block_byref_a_0 {
	  void *__isa;
	__Block_byref_a_0 *__forwarding;
	 int __flags;
	 int __size;
	 int a;
	};
	
结构，其中__forwarding指向自身。因此在block内部就是通过这个指针，来修改block外部的变量。

如下:

	static void __blockMain_block_func_0(struct __blockMain_block_impl_0 *__cself) {
	  __Block_byref_a_0 *a = __cself->a; // bound by ref
	
	        (a->__forwarding->a) = 2;
	        printf("%d", (a->__forwarding->a));
	    }
	    
所以看完编译后的代码，我们就能够知道block的运行逻辑了。