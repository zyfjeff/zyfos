## 第四章: OS的骨干和C++运行库支持

#### 内核运行中的C++

一个内核可以使用C++来编写，使用C++编写的内核和使用C来编写的内核很相似，除了一些你必须要考虑到的错误外(运行库的支持，构造函数，...)

编译器假定所有必须的C++运行库支持,默认都是可用的，但是我们不能去链接libsupc++库到你的C++内核中，我们需要加入一些自己的一些基本函数,这些函数可以在 [cxx.cc](https://github.com/zyfjeff/zyfos/blob/master/src/kernel/runtime/cxx.cc)文件中找到。

**注意:** `new`和`delete` 这两个函数在虚拟内存和分页还没有初始化之前是不能使用的。

#### 基本的C/C++函数

内核是不能使用来自于标准库的函数，我们需要加入一些管理内存和字符串的基本函数。

```cpp
void 	itoa(char *buf, unsigned long int n, int base);

void *	memset(char *dst,char src, int n);
void *	memcpy(char *dst, char *src, int n);

int 	strlen(char *s);
int 	strcmp(const char *dst, char *src);
int 	strcpy(char *dst,const char *src);
void 	strcat(void *dest,const void *src);
char *	strncpy(char *destString, const char *sourceString,int maxLength);
int 	strncmp( const char* s1, const char* s2, int c );
```

这些基本函数在 [string.cc](https://github.com/zyfjeff/zyfos/blob/master/src/kernel/runtime/string.cc), [memory.cc](https://github.com/zyfjeff/zyfos/blob/master/src/kernel/runtime/memory.cc), [itoa.cc](https://github.com/zyfjeff/zyfos/blob/master/src/kernel/runtime/itoa.cc)文件中定义了。

#### C类型

在进行下一步之前,我们将要在我们的代码中去使用不同的类型,大多数的类型都将使用无符号的类型(所有的位都用来存储数,有符号类型则有一位代表符号位):

```cpp
typedef unsigned char 	u8;
typedef unsigned short 	u16;
typedef unsigned int 	u32;
typedef unsigned long long 	u64;

typedef signed char 	s8;
typedef signed short 	s16;
typedef signed int 		s32;
typedef signed long long	s64;
```

#### 编译我们的内核

编译我们的内核和编译linux下的可执行文件一样,我们不能去使用标准库,不能依赖宿主系统.我么的内核[Makefile](https://github.com/zyfjeff/zyfos/blob/master/src/kernel/Makefile) 定义了编译和链接内核的过程.

对于x86架构,下面这些参数在gcc/g++/ld工具中使用:

```
# Linker
LD=ld
LDFLAG= -melf_i386 -static  -L ./  -T ./arch/$(ARCH)/linker.ld

# C++ compiler
SC=g++
FLAG= $(INCDIR) -g -O2 -w -trigraphs -fno-builtin  -fno-exceptions -fno-stack-protector -O0 -m32  -fno-rtti -nostdlib -nodefaultlibs 

# Assembly compiler
ASM=nasm
ASMFLAG=-f elf -o
```

#### 参见
* [编译参数详解](https://github.com/zyfjeff/zyfos/blob/master/附录/编译参数详解.md)
