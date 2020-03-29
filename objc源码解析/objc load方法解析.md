# objc load 方法解析

non-lazy class
实现了+load方法的class是non-lazy class，在ObjC向dyld注册回调的方法中："_dyld_objc_notify_register(&map_images, load_images, unmap_image)"，第一个回调map_images中就会对non-lazy class进执行realizeClass(cls)【对class进行第一次初始化】。而通过打断来看，回调map_imags是在回调load_images之前执行的，也就是说在执行+load方法时，对应的class都是经过第一次初始化的。

作者：tom555cat
链接：https://www.jianshu.com/p/baee25661aeb
来源：简书
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

首先我们应该知道，在运行一个iOS程序的时候，所有类中的load方法都已经加载到内存中，并运行，核心方法是：

	void
	load_images(const char *path __unused, const struct mach_header *mh)
	{
	    // Return without taking locks if there are no +load methods here.
	    if (!hasLoadMethods((const headerType *)mh)) return;
	
	    recursive_mutex_locker_t lock(loadMethodLock);
	
	    // Discover load methods
	    {
	        mutex_locker_t lock2(runtimeLock);
	      
	        // 将所有class与category的load方法放到一个两个列表中
	        prepare_load_methods((const headerType *)mh);
	    }
	
	    // Call +load methods (without runtimeLock - re-entrant)
	    call_load_methods();
	}
	
下面我们对这个方法中的代码逐一分析:

### hasLoadMethods
	
首先我们看到hasLoadMethods方法的实现：

	// Quick scan for +load methods that doesn't take a lock.
	bool hasLoadMethods(const headerType *mhdr)
	{
	    size_t count;
	    if (_getObjc2NonlazyClassList(mhdr, &count)  &&  count > 0) return true;
	    if (_getObjc2NonlazyCategoryList(mhdr, &count)  &&  count > 0) return true;
	    return false;
	}

断点进入了这个方法中，我们可以看到：

	_getObjc2NonlazyClassList(mhdr, &count)  &&  count > 0
	
_getObjc2NonlazyClassList的定义如下：

	GETSECT(_getObjc2NonlazyClassList,    classref_t,      "__objc_nlclslist");
	
然后再看GETSECT:

	// Look for a __DATA or __DATA_CONST or __DATA_DIRTY section 
	// with the given name that stores an array of T.
	template <typename T>
	T* getDataSection(const headerType *mhdr, const char *sectname, 
	                  size_t *outBytes, size_t *outCount)
	{
	    unsigned long byteCount = 0;
	    T* data = (T*)getsectiondata(mhdr, "__DATA", sectname, &byteCount);
	    if (!data) {
	        data = (T*)getsectiondata(mhdr, "__DATA_CONST", sectname, &byteCount);
	    }
	    if (!data) {
	        data = (T*)getsectiondata(mhdr, "__DATA_DIRTY", sectname, &byteCount);
	    }
	    if (outBytes) *outBytes = byteCount;
	    if (outCount) *outCount = byteCount / sizeof(T);
	    return data;
	}
	
	#define GETSECT(name, type, sectname)                                   \
	    type *name(const headerType *mhdr, size_t *outCount) {              \
	        return getDataSection<type>(mhdr, sectname, nil, outCount);     \
	    }                                                                   \
	    type *name(const header_info *hi, size_t *outCount) {               \
	        return getDataSection<type>(hi->mhdr(), sectname, nil, outCount); \
	    }

从上述的源码中我们可以知道，_getObjc2NonlazyClassList方法就是从__DATA段中，查找到__objc_nlclslist，也就是Objective-C 的 +load 函数列表，比 __mod_init_func 更早执行。
然后判断count是否大于1，大于1说明有load方法，直接返回。
	
首先去看类列表中，有没有load方法。如果有的话, 返回true。否者，继续往下走

	_getObjc2NonlazyCategoryList(mhdr, &count)  &&  count > 0
	
去所有的category中看，是否有load方法， 原理同上。

### `prepare_load_methods`

接下来我们看prepare_load_methods方法：

	void prepare_load_methods(const headerType *mhdr)
	{
	    size_t count, i;
	
	    runtimeLock.assertLocked();
	
	    classref_t *classlist = 
	        _getObjc2NonlazyClassList(mhdr, &count);
	    for (i = 0; i < count; i++) {
	        schedule_class_load(remapClass(classlist[i]));
	    }
	
	    category_t **categorylist = _getObjc2NonlazyCategoryList(mhdr, &count);
	    for (i = 0; i < count; i++) {
	        category_t *cat = categorylist[i];
	        Class cls = remapClass(cat->cls);
	        if (!cls) continue;  // category for ignored weak-linked class
	        realizeClass(cls);
	        assert(cls->ISA()->isRealized());
	        add_category_to_loadable_list(cat);
	    }
	}
	
从代码中其实我们就已经可以很清晰的看到实现的原理了，获取到包含load方法的类，然后加入到schedule_class_load中去，category中的load方法同理。

而schedule_class_load的实现如下：

	/***********************************************************************
	* prepare_load_methods
	* Schedule +load for classes in this image, any un-+load-ed 
	* superclasses in other images, and any categories in this image.
	**********************************************************************/
	// Recursively schedule +load for cls and any un-+load-ed superclasses.
	// cls must already be connected.
	static void schedule_class_load(Class cls)
	{
	    if (!cls) return;
	    assert(cls->isRealized());  // _read_images should realize
	
	    if (cls->data()->flags & RW_LOADED) return;
	
	    // Ensure superclass-first ordering
	    schedule_class_load(cls->superclass);
	
	    add_class_to_loadable_list(cls);
	    cls->setInfo(RW_LOADED); 
	}
	
	/***********************************************************************
	* add_class_to_loadable_list
	* Class cls has just become connected. Schedule it for +load if
	* it implements a +load method.
	**********************************************************************/
	void add_class_to_loadable_list(Class cls)
	{
	    IMP method;
	
	    loadMethodLock.assertLocked();
	
	    method = cls->getLoadMethod();
	    if (!method) return;  // Don't bother if cls has no +load method
	    
	    if (PrintLoading) {
	        _objc_inform("LOAD: class '%s' scheduled for +load", 
	                     cls->nameForLogging());
	    }
	    
	    if (loadable_classes_used == loadable_classes_allocated) {
	        loadable_classes_allocated = loadable_classes_allocated*2 + 16;
	        loadable_classes = (struct loadable_class *)
	            realloc(loadable_classes,
	                              loadable_classes_allocated *
	                              sizeof(struct loadable_class));
	    }
	    
	    loadable_classes[loadable_classes_used].cls = cls;
	    loadable_classes[loadable_classes_used].method = method;
	    loadable_classes_used++;
	}
	
首先通过递归，找到当前类，以及他的所有父类，并对所有的这些类，调用add_class_to_loadable_list，注意调用的顺序是，先从父分类开始的，然后不断的往下走。

而在add_class_to_loadable_list方法中我们可以看到，如果这个类没有load方法的话，即，

	 method = cls->getLoadMethod();

则返回。否者继续往下走，判断loadable_classes_used == loadable_classes_allocated， 如果相等，则初始化loadable_classes，然后存入cls，跟method，这里的method表示的是load的实现方式。

### `call_load_methods`

调用所有已经缓存下来的load方法.

		void call_load_methods(void)
		{
			static bool loading = NO;
			bool more_categories;
			
			loadMethodLock.assertLocked();
			
			// Re-entrant calls do nothing; the outermost call will finish the job.
			if (loading) return;
			loading = YES;
			
			void *pool = objc_autoreleasePoolPush();
			
			do {
			    // 1. Repeatedly call class +loads until there aren't any more
			    while (loadable_classes_used > 0) {
			        call_class_loads();
			    }
			
			    // 2. Call category +loads ONCE
			    more_categories = call_category_loads();
			
			    // 3. Run more +loads if there are classes OR more untried categories
			} while (loadable_classes_used > 0  ||  more_categories);
			
			objc_autoreleasePoolPop(pool);
			
			loading = NO;
	}
	
	static void call_class_loads(void)
	{
	    int i;
	    
	    // Detach current loadable list.
	    struct loadable_class *classes = loadable_classes;
	    int used = loadable_classes_used;
	    loadable_classes = nil;
	    loadable_classes_allocated = 0;
	    loadable_classes_used = 0;
	    
	    // Call all +loads for the detached list.
	    for (i = 0; i < used; i++) {
	        // 获取类指针
	        Class cls = classes[i].cls;
	        // 获取方法对象
	        load_method_t load_method = (load_method_t)classes[i].method;
	        if (!cls) continue; 
	
	        if (PrintLoading) {
	            _objc_inform("LOAD: +[%s load]\n", cls->nameForLogging());
	        }
	        // 方法调用
	        (*load_method)(cls, SEL_load);
	    }
	    
	    // Destroy the detached list.
	    // 释放class列表
	    if (classes) free(classes);
	}
	
### 总结

1. Load Images: 通过dyld载入images
2. 通过`prepare_load_methods`，生成全局的有效的class指针与load方法的线性表，无效的类直接过滤。
3. 通过`call_load_methods`，执行全局线性表中的load方法，包括类中与分类中的方法.

### load方法的应用

load方法是在main函数之前执行，并且只会执行一次，因此可以在load的时候执行各种frameword中的方法，或者我们可在load方法中执行method swizzle等等。

	


