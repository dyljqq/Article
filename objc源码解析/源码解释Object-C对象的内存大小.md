### 源码解释Object-C对象的内存大小

首先我们alloc一个NSObject对象，假定为Person，那么我们执行[Person alloc]的时候，会在堆上给我们分配内存，此时会调用:

	+ (id)alloc {
	    return _objc_rootAlloc(self);
	}
	
然后不断往下走之后，最终我们看到分配内存的方法：

	static ALWAYS_INLINE id
	_class_createInstanceFromZone(Class cls, size_t extraBytes, void *zone,
	                              int construct_flags = OBJECT_CONSTRUCT_NONE,
	                              bool cxxConstruct = true,
	                              size_t *outAllocatedSize = nil)
	{

		....
		size_t size;

	    size = cls->instanceSize(extraBytes);
	    if (outAllocatedSize) *outAllocatedSize = size;
	    
	    id obj;
	    if (zone) {
	        obj = (id)malloc_zone_calloc((malloc_zone_t *)zone, 1, size);
	    } else {
	        obj = (id)calloc(1, size);
	    }
	}
	
这里我们知道，size是通过instanceSize方法去获取的，最有意识的是这个方法：

	inline size_t instanceSize(size_t extraBytes) const {
        if (fastpath(cache.hasFastInstanceSize(extraBytes))) {
            return cache.fastInstanceSize(extraBytes);
        }

        size_t size = alignedInstanceSize() + extraBytes;
        // CF requires all objects be at least 16 bytes.
        if (size < 16) size = 16;
        return size;
    }
    
  这里我们可以知道size的最小值为16。所以尽管NSObject只有一个isa的值，指针的大小为8个字节，但是这个对象她的大小应该是16.