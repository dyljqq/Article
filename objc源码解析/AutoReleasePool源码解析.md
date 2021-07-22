今天在看Objective-C高级编程 iOS与OS X多线程和内存管理的时候，翻到了autorelease的章节，但是里面对这块的描述比较模糊，因此，自己去看了相关的代码。理了一下逻辑，如下:

AutoReleasePool:iOS中的自动释放池。我们都知道，iOS使用了引用计数来对对象的内存进行管理。当我们创建一个xcode工程的时候，我们会在main.m中发现这样一段代码:

	int main(int argc, const char * argv[]) {
	    @autoreleasepool {
	        Teacher *teacher = [[Teacher alloc] init];
	    }
	    return 0;
	}
	
那么@autoreleasepool的作用就是替这个作用域中的对象管理引用计数。我们使用clang -rewrite-objc main.m可以从main.cpp中看到如下的代码:

	struct __AtAutoreleasePool {
	  __AtAutoreleasePool() {atautoreleasepoolobj = objc_autoreleasePoolPush();}
	  ~__AtAutoreleasePool() {objc_autoreleasePoolPop(atautoreleasepoolobj);}
	  void * atautoreleasepoolobj;
	};
	
由此我们可以知道， @autoreleasepool {}其实就是在代码段的收尾加上了objc_autoreleasePoolPush与objc_autoreleasePoolPop(atautoreleasepoolobj)。那么我继续看这两个函数都干了什么事情呢？

在了解这个之前，我们需要知道，autoreleasepool底层其实是通过AutoReleasePage来管理对象，每个page有固定的大小，因此当需要管理的对象达到一定数量之后，这个page管理不了了怎么办呢？那当然就是新创建一个page啊，苹果通过双向链表的形式将各个page链接在一起。每个page都会有parent与child指针指向别的page。当一个autoreleasepool中的对象添加完之后，我们会再添加一个哨兵来进行分割，并且返回这个哨兵的内存地址。因此我们在释放的时候，只需要找到这个哨兵对应的内存地址，然后不断往前释放，直到遇到下一个哨兵值即可。

那么什么时候会释放autoreleasepool中的对象呢，很多人可能觉得作用域结束了就释放呗，其实不是的。在没有手动加autoreleasepool的情况下，应该是在runloop结束之后，会做一个统一的释放操作。每个runloop会自动加入一个push跟pop的代码。

那么了解了这些之后，我们来看对饮的代码：

### objc_autoreleasePoolPush

	static inline void *push() 
    {
        id *dest;
        /**
        halt when autorelease pools are popped out of order, and allow heap debuggers to track autorelease pools
        */
        if (slowpath(DebugPoolAllocation)) {
            // Each autorelease pool starts on a new pool page.
            dest = autoreleaseNewPage(POOL_BOUNDARY);
        } else {
            dest = autoreleaseFast(POOL_BOUNDARY);
        }
        ASSERT(dest == EMPTY_POOL_PLACEHOLDER || *dest == POOL_BOUNDARY);
        return dest;
    }
    
   这里面我们需要关注两个方法：
   
   	* autoreleaseNewPage(POOL_BOUNDARY);
   	* autoreleaseFast(POOL_BOUNDARY);

   其中POOL_BOUNDARY其实就是我们说的哨兵值。我们接着看这两个方法的实现:
   
   	static inline id *autoreleaseFast(id obj)
    {
    	//找到当前的page,根据之前的key来获取。static pthread_key_t const key = AUTORELEASE_POOL_KEY;
        AutoreleasePoolPage *page = hotPage(); 
        if (page && !page->full()) { // 如果page存在并且没有满，那么添加obj
            return page->add(obj);
        } else if (page) { // 如果page已经满了，但是parent不为nil，那么就先创建一个新的page，并把obj插入到这个page中
            return autoreleaseFullPage(obj, page);
        } else { // 如果没有page，就创建一个新的page，并且page的parent为nil。
            return autoreleaseNoPage(obj);
        }
    }
    
  
 简化后的添加obj进入page的方法如下：
 
	id *add(id obj) {
		id *ret;
		ret = next;  // faster than `return next-1` because of aliasing
	  *next++ = obj;
	   return ret;
	}
	
将obj的值放入next的地址，然后next下移。其实就是一个入栈的操作。而在调用add的时候，我们已经检查过page的情况，因此不会出现溢出。


### objc_autoreleasePoolPop

	void
	objc_autoreleasePoolPop(void *ctxt)
	{
	    AutoreleasePoolPage::pop(ctxt);
	}
	
	static inline void
    pop(void *token) {
    	page = pageForPointer(token);
    	stop = (id *)token;
    	return popPage<false>(token, page, stop);
    }
    
    static AutoreleasePoolPage *pageForPointer(const void *p) 
    {
        return pageForPointer((uintptr_t)p);
    }

    static AutoreleasePoolPage *pageForPointer(uintptr_t p) 
    {
        AutoreleasePoolPage *result;
        uintptr_t offset = p % SIZE;

        ASSERT(offset >= sizeof(AutoreleasePoolPage));

        result = (AutoreleasePoolPage *)(p - offset);
        result->fastcheck();

        return result;
    }
    
    
    template<bool allowDebug>
    static void
    popPage(void *token, AutoreleasePoolPage *page, id *stop)
    {
        if (allowDebug && PrintPoolHiwat) printHiwat();

        page->releaseUntil(stop);

        // memory: delete empty children
        if (allowDebug && DebugPoolAllocation  &&  page->empty()) {
            // special case: delete everything during page-per-pool debugging
            AutoreleasePoolPage *parent = page->parent;
            page->kill();
            setHotPage(parent);
        } else if (allowDebug && DebugMissingPools  &&  page->empty()  &&  !page->parent) {
            // special case: delete everything for pop(top)
            // when debugging missing autorelease pools
            page->kill();
            setHotPage(nil);
        } else if (page->child) {
            // hysteresis: keep one empty child if page is more than half full
            if (page->lessThanHalfFull()) {
                page->child->kill();
            }
            else if (page->child->child) {
                page->child->child->kill();
            }
        }
    }
    
   这里的代码我们总结一下就是，我们通过之前的push方法拿到了这次的哨兵的地址，然后通过一系列的转换，我们可以拿到这次的pop所在的page，通过不断的将obj出栈，直到next=哨兵的地址停止。
   
   	page->releaseUntil(stop); //主要的出栈逻辑
	