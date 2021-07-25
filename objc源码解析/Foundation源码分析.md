# Foundation源码分析

1. - (BOOL) containsObject: (id)anObject

我们可以通过源码分析出，这个函数在不同的数据结构，实现是不相同的。如在NSArray中与NSSet中，她们的时间复杂度是不相同的：

* 在NSArray中:
  
    Returns YES if anObject belongs to self. No otherwise.<br />
    The [NSObject-isEqual:] method of anObject is used to test for equality.

      - (BOOL) containsObject: (id)anObject
      {
        return ([self indexOfObject: anObject] != NSNotFound);
      }

    oaiSel = @selector(objectAtIndex:);

    eqSel = @selector(isEqual:);

      - (NSUInteger) indexOfObject: (id)anObject
      {
        NSUInteger	c = [self count];

        if (c > 0 && anObject != nil)
        {
            NSUInteger	i;
            IMP	get = [self methodForSelector: oaiSel];
            BOOL	(*eq)(id, SEL, id)
      	= (BOOL (*)(id, SEL, id))[anObject methodForSelector: eqSel];

            for (i = 0; i < c; i++)
      	if ((*eq)(anObject, eqSel, (*get)(self, oaiSel, i)) == YES)
      	  return i;
          }
            return NSNotFound;
        }

    从这里可以看出，每次执行[array containsObject]的时间耗时跟array的数组长度有关，即为O(N)

* 在NSSet中：

      - (BOOL) containsObject: (id)anObject
      {
        return (([self member: anObject]) ? YES : NO);
      }

      - (id) member: (id)anObject
      {
        if (anObject != nil)
          {
            GSIMapNode node = GSIMapNodeForKey(&map, (GSIMapKey)anObject);

            if (node != 0)
      	{
      	  return node->key.obj;
      	}
          }
        return nil;
      }

    这样我们从源码中可以看出，因为NSSet的结构确保了不会存在相同的元素，因此用这个元素做key创建的一个HashMap，这样就可以通过O(1)的时间复杂度就判断出，set中是否包括了指定元素