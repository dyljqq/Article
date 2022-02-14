### iOS基础题

1. 讲一下atomic的实现机制；为什么不能保证绝对的线程安全（最好可以结合场景来说）？

    ```
    我们可以简单的说，atomic修饰的属性，会给访问对应变量时添加对应的自旋转锁，以达到线程安全。

    id objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, BOOL atomic) {
       if (offset == 0) {
           return object_getClass(self);
       }

       // Retain release world
       id *slot = (id*) ((char*)self + offset);
       if (!atomic) return *slot;
           
       // Atomic retain release world
       spinlock_t& slotlock = PropertyLocks[slot];
       slotlock.lock();
       id value = objc_retain(*slot);
       slotlock.unlock();
       
       // for performance, we (safely) issue the autorelease OUTSIDE of the spinlock.
       return objc_autoreleaseReturnValue(value);
    }

    从上面代码看出，在访问被atomic修饰符修饰的属性时，会先通过对应的内存找到锁，然后才会进行访问。

    static inline void reallySetProperty(id self, SEL _cmd, id newValue, ptrdiff_t offset, bool atomic, bool copy, bool mutableCopy)
   {
       if (offset == 0) {
           object_setClass(self, newValue);
           return;
       }

       id oldValue;
       id *slot = (id*) ((char*)self + offset);

       if (copy) {
           newValue = [newValue copyWithZone:nil];
       } else if (mutableCopy) {
           newValue = [newValue mutableCopyWithZone:nil];
       } else {
           if (*slot == newValue) return;
           newValue = objc_retain(newValue);
       }

       if (!atomic) {
           oldValue = *slot;
           *slot = newValue;
       } else {
           spinlock_t& slotlock = PropertyLocks[slot];
           slotlock.lock();
           oldValue = *slot;
           *slot = newValue;        
           slotlock.unlock();
       }

       objc_release(oldValue);
   }

   同访问属性一致，在设置新值的时候，会先取出对应的自旋转锁，然后才会做对应的操作。

    ```

那么加上锁之后，就一定是线程安全的么，也不一定吧，因为我们保证的其实是指针不会被修改，但是指针对应的内存不是线程安全的。

```

@property (atomic, copy) NSArray *names;

- (void)printNames {
    
    // Thead one
    for (int i = 0; i < 10000; i++) {
        if (i % 2 == 0) {
            self.names = @[@"1", @"2", @"3", @"4"];
        } else {
            self.names = @[@"1"];
        }
    }
    
    // Thread two
    for (int i = 0; i < 10000; i++) {
        if (self.names.count > 2) {
            NSString *name = [self.names objectAtIndex:1];
            NSLog(@"name: %@", name);
        }
    }
}

运行之后，会出现crash，就是因为线程一修改了names的内存数据，线程二在判定时是符合条件的，但是在取值的时候，就会取到被修改的内容，因此atomic也并不是一定安全的。而且因为加了锁之后，会比较影响app的性能，所以我们都会使用nonatomic修饰，然后在需要对值做线程安全的地方，我们加上对应的锁进行限制。

```

2. 被weak修饰的对象在被释放的时候会发生什么？是如何实现的？知道sideTable么？里面的结构可以画出来么？

首先我们都知道一个被修饰为weak的变量是不会增加引用计数的，并且对应的对象被释放的时候，这个weak object就会被置为nil。通常都是用于解决循环引用问题。

Runtime其实维护了一个weak object表，用于存储指向某个对象的所有weak指针。

* 初始化时，会调用objc_initWeak方法

```
location weak对象指向的指针
newObject 指向的对象
id
objc_initWeak(id *location, id newObj)
{
    if (!newObj) {
        *location = nil;
        return nil;
    }

    return storeWeak<DontHaveOld, DoHaveNew, DoCrashIfDeallocating>
        (location, (objc_object*)newObj);
}
```

* 添加weak对象的时候会调用objc_storeWeak()

```
id
objc_storeWeak(id *location, id newObj)
{
    return storeWeak<DoHaveOld, DoHaveNew, DoCrashIfDeallocating>
        (location, (objc_object *)newObj);
}
```

* 当指向的对象被释放的时候，会从weak表中进行删除。

```
struct SideTable {
    spinlock_t slock;
    RefcountMap refcnts;
    weak_table_t weak_table;

    SideTable() {
        memset(&weak_table, 0, sizeof(weak_table));
    }

    ~SideTable() {
        _objc_fatal("Do not delete SideTable.");
    }

    void lock() { slock.lock(); }
    void unlock() { slock.unlock(); }
    void forceReset() { slock.forceReset(); }

    // Address-ordered lock discipline for a pair of side tables.

    template<HaveOld, HaveNew>
    static void lockTwo(SideTable *lock1, SideTable *lock2);
    template<HaveOld, HaveNew>
    static void unlockTwo(SideTable *lock1, SideTable *lock2);
};
```