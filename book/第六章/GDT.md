## 第六章: GDT

   感谢GRUB,因为GRUB使我们的内核不再是实模式了，但是仍然是在[保护模式](http://en.wikipedia.org/wiki/Protected_mode),这个模式允许我们使用微处理器尽可能的功能例如虚拟内存管理，分页和安全的多任务等．

#### GDT是什么?

[GDT](http://en.wikipedia.org/wiki/Global_Descriptor_Table) ("Global Descriptor Table") 是一个用来定义不同内存区域基地址大小和像执行和写这样的访问权限的数据结构，这些内存区域我们称之为段．

我们将使用GDT去定义不同的内存段．

* *"code"*: 内核的代码段，用于存储可执行的二进制代码．kernel code, used to stored the executable binary code
* *"data"*: 内核的数据段
* *"stack"*: 内核的堆栈段，用于存储内核执行时存储函数调用的栈．
* *"ucode"*: 用于代码段，用于存储用户的二进制代码．
* *"udata"*: 用户程序的数据段．
* *"ustack"*: 用户堆栈段，用于存储用户空间存储函数调用时的栈．

#### 如何载入GDT?

GRUB会初始化GDT,但是这个初始化后的GDT对于我们内核来说不是正确的，GDT是用过使用LGDT汇编指令载入的，一个GDT描述符结构的预期位置如下:

![GDTR](./gdtr.png)

And the C structure:

```cpp
struct gdtr {
	u16 limite;
	u32 base;
} __attribute__ ((packed));
```

**注意:** 指令 ```__attribute__ ((packed))``` 是gcc提供的扩展功能意思就是说对于这个结构体我们应该使用最少的内存来存储. 没有这个指令的话, gcc会为了优化程序在执行过程访问内存而包含一些字节来让内存对齐．

我们需要去定义我们自己的GDT表，并通过使用LGDT指令载入这个GDT数据结构，GDT表我们可以存储在内存的任意地方，它的地址应该是通过GDTR寄存器来告知进程的．

GDT表中的段的组成是由下面这个结构来表示．
The GDT table is composed of segments with the following structure:

![GDTR](./gdtentry.png)

And the C structure:

```cpp
struct gdtdesc {
	u16 lim0_15;
	u16 base0_15;
	u8 base16_23;
	u8 acces;
	u8 lim16_19:4;
	u8 other:4;
	u8 base24_31;
} __attribute__ ((packed));
```

#### 如何去定义我们的GDT表?

我们现在需要在内存中定义我们的GDT,最终通过使用GDTR寄存器来载入GDT．

我们将使用下面这个地址来存储我们的GDT

```cpp
#define GDTBASE	0x00000800
```

函数 **init_gdt_desc** 在[x86.cc](https://github.com/zyfjeff/zyfos/blob/master/src/kernel/arch/x86/x86.cc) 作用就是用来初始化gdt段描述符的．

```cpp
void init_gdt_desc(u32 base, u32 limite, u8 acces, u8 other, struct gdtdesc *desc)
{
	desc->lim0_15 = (limite & 0xffff);
	desc->base0_15 = (base & 0xffff);
	desc->base16_23 = (base & 0xff0000) >> 16;
	desc->acces = acces;
	desc->lim16_19 = (limite & 0xf0000) >> 16;
	desc->other = (other & 0xf);
	desc->base24_31 = (base & 0xff000000) >> 24;
	return;
}
```

函数 **init_gdt** 功能是初始化GDT, 下面这些字段将在之后进行解释，目的是为了使用多任务的功能．

```cpp
void init_gdt(void)
{
	default_tss.debug_flag = 0x00;
	default_tss.io_map = 0x00;
	default_tss.esp0 = 0x1FFF0;
	default_tss.ss0 = 0x18;

	/* initialize gdt segments */
	init_gdt_desc(0x0, 0x0, 0x0, 0x0, &kgdt[0]);
	init_gdt_desc(0x0, 0xFFFFF, 0x9B, 0x0D, &kgdt[1]);	/* code */
	init_gdt_desc(0x0, 0xFFFFF, 0x93, 0x0D, &kgdt[2]);	/* data */
	init_gdt_desc(0x0, 0x0, 0x97, 0x0D, &kgdt[3]);		/* stack */

	init_gdt_desc(0x0, 0xFFFFF, 0xFF, 0x0D, &kgdt[4]);	/* ucode */
	init_gdt_desc(0x0, 0xFFFFF, 0xF3, 0x0D, &kgdt[5]);	/* udata */
	init_gdt_desc(0x0, 0x0, 0xF7, 0x0D, &kgdt[6]);		/* ustack */

	init_gdt_desc((u32) & default_tss, 0x67, 0xE9, 0x00, &kgdt[7]);	/* descripteur de tss */

	/* initialize the gdtr structure */
	kgdtr.limite = GDTSIZE * 8;
	kgdtr.base = GDTBASE;

	/* copy the gdtr to its memory area */
	memcpy((char *) kgdtr.base, (char *) kgdt, kgdtr.limite);

	/* load the gdtr registry */
	asm("lgdtl (kgdtr)");

	/* initiliaz the segments */
	asm("   movw $0x10, %ax	\n \
            movw %ax, %ds	\n \
            movw %ax, %es	\n \
            movw %ax, %fs	\n \
            movw %ax, %gs	\n \
            ljmp $0x08, $next	\n \
            next:		\n");
}
```
