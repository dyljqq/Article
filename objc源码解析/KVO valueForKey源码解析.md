# KVO valueForKey 源码解析

首先我是通过阅读GNUBase中的源码，来了解KVC的一些函数的调用过程，会跟苹果自身的Foundation有一些出入。

在KeyValueCoding文件中我们找到了如下的方法:

	- (id) valueForKey: (NSString*)aKey
	{
	  unsigned	size = [aKey length] * 8; // 这里猜测应该是某些文字的解码可能会占用8个字节，这里给了一个足够大的空间
	  char		key[size + 1];
	
	  [aKey getCString: key
		 maxLength: size + 1
		  encoding: NSUTF8StringEncoding];
	  size = strlen(key); // 这里重新计算size值。如如果key是一个中文字符串的话，那么 size = 3 * aKey.length
	  return ValueForKey(self, key, size);
	}
	
很巧的是，我们也能看到getCString方法的大致实现，他其实就是一个将NSString的数据给塞到char数组中的操作，并返回是否成功的结果。

	- (BOOL) getCString: (char*)buffer
		  maxLength: (NSUInteger)maxLength
		   encoding: (NSStringEncoding)encoding
	{
	  if (0 == maxLength || 0 == buffer) return NO;
	  if (encoding == NSUnicodeStringEncoding)
	    {
	      unsigned	length = [self length];
	
	      if (maxLength > length * sizeof(unichar))
		{
		  unichar	*ptr = (unichar*)(void*)buffer;
	
		  maxLength = (maxLength - 1) / sizeof(unichar);
		  [self getCharacters: ptr
				range: NSMakeRange(0, maxLength)];
		  ptr[maxLength] = 0;
		  return YES;
		}
	      return NO;
	    }
	  else
	    {
	      NSData	*d = [self dataUsingEncoding: encoding];
	      unsigned	length = [d length];
	      BOOL	result = (length < maxLength) ? YES : NO;
	
	      if (d == nil)
	        {
		  [NSException raise: NSCharacterConversionException
			      format: @"Can't convert to C string."];
		}
	      if (length >= maxLength)
	        {
	          length = maxLength-1;
		}
	      memcpy(buffer, [d bytes], length);
	      buffer[length] = '\0';
	      return result;
	    }
	}
	
接下来我们看ValueForKey方法的实现：

	static id ValueForKey(NSObject *self, const char *key, unsigned size)
	{
	  SEL		sel = 0;
	  int		off = 0;
	  const char	*type = NULL;
	
	  if (size > 0)
	    {
	      const char	*name;
	      char		buf[size + 5];
	      char		lo;
	      char		hi;
	
	      memcpy(buf, "_get", 4);
	      memcpy(&buf[4], key, size);
	      buf[size + 4] = '\0'; buff = _get + key + '\0'
	      lo = buf[4];
	      hi = islower(lo) ? toupper(lo) : lo;
	      buf[4] = hi; //将key的首字母大写
	
	      name = &buf[1];	// getKey
	      sel = sel_getUid(name);  // 找到缓存的selector，具体实现可以往下看
	      if (sel == 0 || [self respondsToSelector: sel] == NO) // 如果没有的话
		{
		  buf[4] = lo; // getKey -> getkey, 去除之前做的toupper(lo) 再做一遍查找的操作
		  name = &buf[4];	// key
		  sel = sel_getUid(name);
		  if (sel == 0 || [self respondsToSelector: sel] == NO)
		    {
	              buf[4] = hi;
	              buf[3] = 's';
	              buf[2] = 'i';
	              name = &buf[2];	// isKey
	              sel = sel_getUid(name);
	              if (sel == 0 || [self respondsToSelector: sel] == NO)
	                {
	                  sel = 0;
	                }
		    }
		}
	
	      if (sel == 0 && [[self class] accessInstanceVariablesDirectly] == YES)
		{
		  buf[4] = hi;
		  name = buf;	// _getKey
		  sel = sel_getUid(name);
		  if (sel == 0 || [self respondsToSelector: sel] == NO)
		    {
		      buf[4] = lo;
		      buf[3] = '_';
		      name = &buf[3];	// _key
		      sel = sel_getUid(name);
		      if (sel == 0 || [self respondsToSelector: sel] == NO)
			{
			  sel = 0;
			}
		    }
		  if (sel == 0)
		    {
		      if (GSObjCFindVariable(self, name, &type, &size, &off) == NO)
			{
	                  buf[4] = hi;
	                  buf[3] = 's';
	                  buf[2] = 'i';
	                  buf[1] = '_';
	                  name = &buf[1];	// _isKey
			  if (!GSObjCFindVariable(self, name, &type, &size, &off))
	                    {
	                       buf[4] = lo;
	                       name = &buf[4];		// key
			       if (!GSObjCFindVariable(self, name, &type, &size, &off))
	                         {
	                            buf[4] = hi;
	                            buf[3] = 's';
	                            buf[2] = 'i';
	                            name = &buf[2];	// isKey
	                            GSObjCFindVariable(self, name, &type, &size, &off);
	                         }
	                    }
			}
		    }
		}
	    }
	  return GSObjCGetVal(self, key, sel, type, size, off);
	}
	
其实就是把key转换成了getKey,isKey,_isKey,_getKey,key,_key。

通过GSObjCFindVariable方法获取到对应的type（编码类型），size(大小)与offset（偏移量）

最后调用GSObjCGetVal拿到事例方法的值。
	
我们来看下sel_getUid方法的实现：

	SEL sel_getUid(const char *name) {
	    return __sel_registerName(name, 2, 1);  // YES lock, YES copy
	}
	
	static SEL __sel_registerName(const char *name, bool shouldLock, bool copy) 
	{
	    SEL result = 0;
	
	    if (shouldLock) selLock.assertUnlocked();
	    else selLock.assertLocked();
	
	    if (!name) return (SEL)0;
	
	    result = search_builtins(name); // 这里我理解是是否是内建的方法： _dyld_get_objc_selector
	    if (result) return result;
	    
	    conditional_mutex_locker_t lock(selLock, shouldLock);
		auto it = namedSelectors.get().insert(name); // 然后在这个共享的数据结构中去找是否有这个SEL
		if (it.second) {
			// No match. Insert.
			*it.first = (const char *)sel_alloc(name, copy);
		}
		return (SEL)*it.first;
	}
	
	static SEL search_builtins(const char *name) 
	{
	#if SUPPORT_PREOPT
	  if (SEL result = (SEL)_dyld_get_objc_selector(name))
	    return result;
	#endif
	    return nil;
	}