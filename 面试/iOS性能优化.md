# iOS性能优化

[主要参考文章](https://ming1016.github.io/2017/06/20/deeply-ios-performance-optimization/)

### 时间复杂度的优化

在我们调用oc或者swift中内建的方法的时候，我门最好知道一下这些方法的实现方式，或者说她们的时间复杂度。如：

在OC中，NSArray中的containsObject的时间复杂度为O(N), NSSet的时间复杂度却为O(1)。因此，如果又一个函数的参数为一个数组，并且这个数组的N非常大，那么当调用containsObject的时候，就会非常耗时，那么我们就可以使用一些其他的方式降低时间复杂度来做性能的优化。

而在NSSet中，containsObject是通过hashmap的形式实现的查找的，因此就不存在性能问题，时间复杂度为O(1)。

### 使用多线程

使用多线程来将一些耗时的操作移到非主线程上操作。可以使用GCD或者NSOperation。然后将一些复杂的操作进行异步的处理，这样可以加快处理的速度。来达到性能优化的目的。但是使用多线程一定要规范，不然会造成一些比较奇怪并且难以定位的问题。

### I/O性能的优化

I/O的操作都非常的耗时，因此应该尽可能的减少这方面的操作。

    * 整合一些零碎的内容作为整体写入
    * 使用合适的I/O操作API
    * 使用合适的线程
    * 使用NSCache作为缓存

文件的持久化：

    1. 使用UserDefaults
    2. 使用FileManager做文件的存储
    3. 文件的归档跟解档
    4. 数据库的操作

NSCache的源码解析

	NSCache其实我理解是一个管理着NSMutableDictionary的对象，这个对象会根据一些策略来释放内存，在内存报警时。或者说，通过实现LRU的策略来决定，当达到一定量的时候，释放最近最少使用的对象。存在NSCache中的对象结构如下:

          @interface _GSCachedObject : NSObject
          {
              @public
              id object;
              NSString *key;
              int accessCount; // 访问次数，过期清理的策略
              NSUInteger cost;
              BOOL isEvictable; // 线程安全
          }
          @end

    当插入一个对象的时候：

        - (void) setObject: (id)obj forKey: (id)key cost: (NSUInteger)num
        {
            _GSCachedObject *oldObject = [_objects objectForKey: key];
			  _GSCachedObject *newObject;
			
			  if (nil != oldObject)
			    {
			      [self removeObjectForKey: oldObject->key];
			    }
			    
			   // 根据LRU算法清理NSCache
			  [self _evictObjectsToMakeSpaceForObjectWithCost: num];
			  newObject = [_GSCachedObject new];
			  // Retained here, released when obj is dealloc'd
			  newObject->object = RETAIN(obj);
			  newObject->key = RETAIN(key);
			  newObject->cost = num;
			  if ([obj conformsToProtocol: @protocol(NSDiscardableContent)])
			    {
			      newObject->isEvictable = YES;
			      [_accesses addObject: newObject];
			    }
			  [_objects setObject: newObject forKey: key];
			  RELEASE(newObject);
			  _totalCost += num;
			}
			
	获取对象：
	
		- (id) objectForKey: (id)key
		{
		  _GSCachedObject *obj = [_objects objectForKey: key];
		
		  if (nil == obj)
		    {
		      return nil;
		    }
		    // LRU策略
		  if (obj->isEvictable)
		    {
		      // Move the object to the end of the access list.
		      [_accesses removeObjectIdenticalTo: obj];
		      [_accesses addObject: obj];
		    }
		  obj->accessCount++;
		  _totalAccesses++;
		  return obj->object;

		}
		
NSCache在SDWebImage的使用:


### 控制App的唤醒次数

如定位服务


### 内存对于性能的影响

就是尽量减少计算，业务规整，合并定时器任务。

### 通过线程找到卡顿信息的代码

	class DJMonitor {
	    
	    static let shared = DJMonitor()
	    
	    var isMoniting = false
	    var timeoutCount = 0
	    var runLoopActivity: CFRunLoopActivity = .entry
	    var dispatchSemaphore: DispatchSemaphore?
	    
	    var runloopObserver: CFRunLoopObserver?
	    
	    func start() {
	        guard !isMoniting else {
	            return
	        }
	        
	        self.runloopObserver = buildRunLoopObserver()
	        if self.runloopObserver == nil {
	            print("创建监听失败...")
	            return
	        }
	        
	        isMoniting = true
	        self.dispatchSemaphore = DispatchSemaphore(value: 0)
	        CFRunLoopAddObserver(CFRunLoopGetMain(), runloopObserver, CFRunLoopMode.commonModes)
	        
	        DispatchQueue.global().async {
	            while true {
	                let wait = self.dispatchSemaphore?.wait(timeout: DispatchTime.now() + .milliseconds(50))
	                if DispatchTimeoutResult.timedOut == wait {
	                    guard self.runloopObserver != nil else {
	                        self.dispatchSemaphore = nil
	                        self.runLoopActivity = .entry
	                        return
	                    }
	                    
	                    if self.runLoopActivity == .beforeSources || self.runLoopActivity == .afterWaiting {
	                        if self.timeoutCount < 5 {
	                            self.timeoutCount += 1
	                            continue
	                        }
	                        
	                        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
	                            print("is something block, check the cpu info...")
	                        }
	                    }
	                }
	                
	                self.timeoutCount = 0
	            }
	        }
	        
	    }
	    
	    func end() {
	        guard self.runloopObserver != nil else {
	            return
	        }
	        self.isMoniting = false
	        self.dispatchSemaphore = nil
	        CFRunLoopRemoveObserver(CFRunLoopGetMain(), self.runloopObserver, CFRunLoopMode.commonModes)
	        self.runloopObserver = nil
	    }
	    
	    private func buildRunLoopObserver() -> CFRunLoopObserver? {
	        let info = Unmanaged<DJMonitor>.passUnretained(self).toOpaque()
	        var context = CFRunLoopObserverContext(version: 0, info: info, retain: nil, release: nil, copyDescription: nil)
	        let observer = CFRunLoopObserverCreate(kCFAllocatorDefault, CFRunLoopActivity.allActivities.rawValue, true, 0, runLoopObserverCallback(), &context)
	        return observer
	    }
	    
	    
	    func runLoopObserverCallback() -> CFRunLoopObserverCallBack {
	        return { observer, activity, info in
	            guard let info = info else {
	                return
	            }
	            
	            let weakSelf = Unmanaged<DJMonitor>.fromOpaque(info).takeUnretainedValue()
	            weakSelf.runLoopActivity = activity
	            weakSelf.dispatchSemaphore?.signal()
	        }
	    }
	    
	    @discardableResult
	    func outputActivityInfo(_ activity: CFRunLoopActivity) -> String {
	        var msg = "RunLoop Activity Status:"
	        switch activity {
	        case .entry: msg += "Entry"
	        case .beforeTimers: msg += "即将处理Timer..."
	        case .beforeSources: msg += "即将处理Source"
	        case .beforeWaiting: msg += "即将进入休眠"
	        case .afterWaiting: msg += "刚从休眠中醒来"
	        case .exit: msg += "即将推出runloop"
	        case .allActivities: msg += "all"
	        default: msg += "default"
	        }
	        
	        print(msg)
	        return msg
	    }
	}