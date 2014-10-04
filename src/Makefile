SDKDIR=./sdk

#你需要提前了解下makefile文件的编写语法和格式。

#使用make的时候输出一个帮助信息,因为help是makefile文件中的第一个目标
#所以当执行make的时候就执行help下面的命令 @是关闭回显,意思就是不输出echo命令
#内容本身,先输出命令的执行结果。
help:
	@echo "Makefile for Building Dev Operating System."
	@echo "Usage: make [ all | clean | help | build | run] " 
	@echo ""
	@echo

#all目标主要是编译kernel,sdk,userland目录下的可执行文件
#make -C 意思就是进入到指定目录执行make命令
all: 
	@echo "Building Kernel"
	make -C ./kernel
	@echo "Building SDK"
	make -C ./sdk
	@echo "Building Userland"
	make -C ./userland
	
#构建OS压缩文件，对OS总体打包。
build:
	zip -r devos-$(VERSION).zip ./

#执行diskimage.sh(创建img镜像文件，格式化文件系统，安装grub,拷贝相关文件等)
#脚本然后使用qemu仿真器进行仿真从镜像文件启动os
run:
	@echo "Running Dev Operating System."
	cd ./sdk && sudo bash ./diskimage.sh
	cd ./sdk && ./qemu.sh

#进入到kernel和userland等目录执行make clean,清楚编译的时候产生的临时文件
clean:
	make -C ./kernel clean
	make -C ./userland clean
