## 第三章: 首先从GRUB启动

#### 启动工作是怎么样的?

当一个基于x86结构的计算机启动的时候，在一开始的时候有一个复杂的过程才能将控制权转交给我们的内核'main'例程('内核里面是kmain()函数')，对于这个课程来说，我们主要考虑的是BIOS这种启动方式，而不是BIOS的继承者(UEFI)。

> 注: UEFI标准是"Unified Extensible Firmware Interface"，UEFI定义了对个人计算机操作系统和硬件平台接口的一个新的模型。这个接口包含了一个数据表，这个数据表包含了与平台相关的信息，并且加入了启动和运行服务的一些系统调用，为操作系统载入和展开的的时候提供了标准的启动操作系统和预先启动程序的环境。

BIOS的启动顺序是:RAM探测 -> 硬件探测/初始化 -> 启动

这个最重要的步骤是"启动",这个步骤是BIOS如何在初始化后试图将控制权转移给下一个阶段bootloader进程。

在"启动"过程中，BIOS将会试图决定一个启动设备(比如:软盘，硬盘，CD，USB闪存设备和网络)。我们的操作系统初始的时候将会从硬盘启动(
但是之后可能从CD，或者是USB闪存设备启动)
一个设备是否是可启动的，取决于启动扇区是否包含一个有效的验证字节，在第一个扇区的511和512偏移处的内容是否是0x55和0xAA(
这个字节称为MBR(Master Boot Record)的魔数,这个验证自己的二进制形式是0b1010101001010101这个交错的位模式被认为是对某些故障的保护(
驱动和控制器的故障),如果这个位模式乱码或者是0x00,那么这个设备就不被认为是可启动的设备)。


BIOS物理的搜索启动设备,并且载入每一个启动设备的启动扇区的第一个512个字节到物理内存的0x7C00(1 KiB below the 32 KiB mark)
处，当探测到启动设备的验证字节是有效的，那么BIOS就将控制权转移到内存的0x7C00处(通过jump指令跳转)
。目的是为了执行启动扇区中的代码。

在这个过程中CPU一直是运行在16位的实模式下(x86 CPUS的默认状态是16位的实模式，目的是为了维持其向后兼容性)
。为了去执行内核的32位指令，bootloader需要将CPU切换到保护模式中。

#### GRUB是什么?

> GNU GRUB(是GNU GRand Unified Bootloader的缩写)是GNU项目中的一个启动加载软件，GRUB参考了自由软件基金会的多启动规格实施的。它提
供给用户一个选择，可以选择从安装在计算机上的多个操作系统中选择一个来启动，以及可以选择在从特定的操作系统分区中的一个内核配置启动
。

为了让这一切简单，GRUB的第一件事就是从机器启动，然后将会从硬盘上载入我们的内核。

#### 我们为什么使用GRUB?

* GRUB非常容易使用
* 不需要写实模式下的16位代码就可以简单的载入32位保护模式的内核代码
* 多启动的支持(可以启动linux,windows以及其它OS)
* 使用GRUB很容易在内存中载入其它模块

#### 怎么去使用GRUB?

GRUB使用了多启动的规格，为了去执行32位的二进制程序，这个二进制程序必须包含一个特殊的头部在开始的第一个8192个字节。我们的内核将会是ELF的可执行文件("Executable and Linkable Format",一个在大多数UNIX系统中的可执行文件的通用的标准的文件格式)

我们内核启动的第一步使用汇编写的[start.asm](https://github.com/zyfjeff/zyfos/blob/master/src/kernel/arch/x86/start.asm)我们使用连接器文件去定义我们可执行文件的结构[linker.ld](https://github.com/zyfjeff/zyfos/blob/master/src/kernel/arch/x86/linker.ld).

启动过程中也需要初始化我们的C++运行库，将会在下一个章节对这个部分进行描述。

多启动的头部结构:

```cpp
struct multiboot_info {
	u32 flags;
	u32 low_mem;
	u32 high_mem;
	u32 boot_device;
	u32 cmdline;
	u32 mods_count;
	u32 mods_addr;
	struct {
		u32 num;
		u32 size;
		u32 addr;
		u32 shndx;
	} elf_sec;
	unsigned long mmap_length;
	unsigned long mmap_addr;
	unsigned long drives_length;
	unsigned long drives_addr;
	unsigned long config_table;
	unsigned long boot_loader_name;
	unsigned long apm_table;
	unsigned long vbe_control_info;
	unsigned long vbe_mode_info;
	unsigned long vbe_mode;
	unsigned long vbe_interface_seg;
	unsigned long vbe_interface_off;
	unsigned long vbe_interface_len;
};
```

你可以使用命令```mbchk kernel.elf```去验证你的kernel.elf文件是否符合多启动标准。你也可以使用这个命令```nm -n kernel.elf```去验证ELF二进制文件的不同偏移处的对象的有效性。

> kernle.elf这个文件是同make all来编译生成的内核镜像文件，后面会说到。

#### 为我们的内核和grub创建一个磁盘镜像

这个脚本[diskimage.sh](https://github.com/zyfjeff/zyfos/blob/master/src/sdk/diskimage.sh) 将会通过使用QEMU帮助我们生成一个硬盘的镜像文件。

第一步是使用qemu-img去生成一个硬盘镜像文件(c.img)。

```
qemu-img create c.img 2M
```

我们现在需要使用fdisk给我们的镜像文件分区。

```bash
fdisk ./c.img

# Switch to Expert commands
> x

# Change number of cylinders (1-1048576)
> c
> 4

# Change number of heads (1-256, default 16):
> h
> 16

# Change number of sectors/track (1-63, default 63)
> s
> 63

# Return to main menu
> r

# Add a new partition
> n

# Choose primary partition
> p

# Choose partition number
> 1

# Choose first cylinder (1-4, default 1)
> 1

# Choose last cylinder, +cylinders or +size{K,M,G} (1-4, default 4)
> 4

# Toggle bootable flag
> a

# Choose first partition for bootable flag
> 1

# Write table to disk and exit
> w
```

我们现在需要将创建的分区通过losetup附加到回环设备上(它运行一个文件像块设备一样去访问)
，这个分区的偏移作为lostup的一个参数，这个偏移的计算方法是: **offset= start_sector * bytes_by_sector**。

Using ```fdisk -l -u c.img```, you get: 63 * 512 = 32256.

```bash
losetup -o 32256 /dev/loop1 ./c.img
```

在这个新的设备上需要创建EXT2文件系统

```bash
mke2fs /dev/loop1
```

我们copy我们的文件到这个挂载的磁盘上

```bash
mount  /dev/loop1 /mnt/
cp -R bootdisk/* /mnt/
umount /mnt/
```

安装GRUB到这个磁盘上

```bash
grub --device-map=/dev/null << EOF
device (hd0) ./c.img
geometry (hd0) 4 16 63
root (hd0,0)
setup (hd0)
quit
EOF
```

最后我们从回环设备中分离磁盘镜像文件。
And finally we detach the loop device:

```bash
losetup -d /dev/loop1
```

####  参见
* [GNU GRUB on Wikipedia](http://en.wikipedia.org/wiki/GNU_GRUB)
* [Multiboot specification](https://www.gnu.org/software/grub/manual/multiboot/multiboot.html)
* [为什么MBR加载到0x7c00处](https://github.com/zyfjeff/zyfos/blob/master/附录/第三章/为什么MBR加载到内存0x7c00处.md)
