# Swift中Enum数据结构的内存分布问题

### 最简单的Enum结构

首先我们从最简单的一个enum说起，我们先定义一个:

	enum Person {
	    case teacher
	    case student
	}
	
然后我们定义一个变量:

	var person = Person.student
	person = Person.teacher
	
然后查看运行时他们的汇编信息，如下:

	 movb   $0x1, 0x5068(%rip)        ; lazy protocol witness table cache variable for type MemoryLayoutTest.Person and conformance MemoryLayoutTest.Person : Swift.Equatable in MemoryLayoutTest + 7
	 movb   $0x0, 0x5046(%rip)        ; lazy protocol witness table cache variable for type MemoryLayoutTest.Person and conformance MemoryLayoutTest.Person : Swift.Equatable in MemoryLayoutTest + 7
	 
movb在汇编中是单个字节的运算符，所以我们推测Person的数据只占有一个字节，并且teacher与student在内部通过0与1进行区分。

验证环节，我们可以通过MemoryLayout来打印一下Person的内存结构，如下：

	memory size: 1
	memory stride: 1
	memory alignment: 1
	
初步证实了我们的猜想。

### 带有关联值的Enum

	enum Person {
	    case teacher(Int)
	    case student
	}
	
	var person = Person.student
	person = Person.teacher(10)
	
这时候我们在teacher中定义了一个Int值，用来表示老师的教龄。那么汇编一下，我们可以看到:

* student:
	
		0x10000341c <+12>:  movq   $0x0, 0x4c41(%rip)        ; _dyld_private + 4
   	 	0x100003427 <+23>:  movb   $0x1, 0x4c42(%rip)        ; MemoryLayoutTest.person : MemoryLayoutTest.Person + 7	
* teacher:

		0x100003450 <+64>:  movq   $0xa, 0x4c0d(%rip)        ; _dyld_private + 4
    		0x10000345b <+75>:  movb   $0x0, 0x4c0e(%rip)        ; MemoryLayoutTest.person : MemoryLayoutTest.Person + 7
    		
  从这里我们可以看出，这个时候Person这个结构理论上应该是8(Int占8个字节) + 1(本身) = 9个字节，但是实际上因为内存对齐的关系，实际上应该是占有8 + 8 = 16个字节。然后最后的那八个字节用来区分枚举的类型。
  
  打印内存信息验证我们的猜想:
  
	  	memory size: 9 // 实际内存
		memory stride: 16 // 分配内存
		memory alignment: 8 // 对齐方式
		
### 枚举值绑定字符串常量的情况

	enum Person: String {
	    case teacher = "Teacher"
	    case student = "Student"
	    case president = "President"
	}
	
	var person = Person.student
	var value = person.rawValue
	person = Person.teacher

我们先来说下，Person的内存情况如下:

	memory size: 1
	memory stride: 1
	memory alignment: 1
	
跟没有绑定常量值的时候一模一样，所以我们可以说，绑定字符串常量，并不会影响enum的内存分布。那么为什么呢，他的内部又是如何通过枚举的值，来对应获取到对应的字符串的呢。我们还是切换到汇编源码，我这里罗列一下重要的部分：

* MemoryLayoutTest`Person.rawValue.getter:
	
		0x100003630 <+16>:  testb  %dil, %dil
		0x100003637 <+23>:  je     0x100003648               ; <+40> at main.swift:45:20
	
	   	0x100003639 <+25>:  jmp    0x10000363b               ; <+27> at <compiler-generated>
	   	0x100003648 <+40>:  leaq   0x744(%rip), %rdi         ; "Teacher"
	   	
	   	0x100003668 <+72>:  leaq   0x72c(%rip), %rdi         ; "Student"
	   	
    		0x100003688 <+104>: leaq   0x714(%rip), %rdi         ; "President"
    		
    通过这段汇编代码，我们可以知道，当执行person.rawValue时，其实相当于调用了一个getRawValue的方法，内部实现如下：
    
    		func getRawValue(person: Person) -> String {
		    switch person {
		    case .teacher: return "Teacher"
		    case .student: return "student"
		    case .president: return "president"
		    }
		}
		
其实这里的参数，改为其内部绑定的值更加合理一些，比如student对应的值其实应该为1.但是为了理解方便，我还是用了person这个变量。
		