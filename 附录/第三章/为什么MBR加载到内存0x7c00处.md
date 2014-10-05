##The mysteries arround "0x7C00" in x86 architecture bios bootloader

	Do you know "0x7C00", a magic number, in x86 assembler programming ? 
"0x7C00" is the memory address which BIOS loads MBR(Master Boot Record, a first sector in hdd/fdd) into. OS or bootloader developer must assume that their assembler codes are loaded and start from 0x7C00. 
But...
- 1st, you may wonder. 
> "I read all of Intel x86(32bit) programmers manual, but did not found the magic number 0x7C00." 

Yes.0x7C00 is NOT related to x86 CPU. It's natural that you couldn't find out it in cpu specifications from intel. Then, you wonder, "Who decided it ?" 

- 2nd, you may wonder: 

> "0x7C00 is 32KiB - 1024B at decimal number. What's this number means ?" 

Anyone decided it. But, why he/she decided such a halfway address? 

Hum...There're TWO questions(mysteries) arround the magic number "0x7C00". 
- Who decided "0x7C00" ?
- What "0x7C00 = 32KiB - 1024B" means ?

Okay, let's dive into the secret of BIOS for "IBM PC 5150", ancestor of modern x86(32bit) PCs, with me...!! 

##"0x7C00" First appeared in IBM PC 5150 ROM BIOS INT 19h handler.

Wandering arround the history of x86 IBM Compatible PC, you know IBM PC 5150 is the ancestor of modern x86(32bit) IBM PC/AT Compatible PCs. 
This PC was released at 1981 August, with Intel 8088(16bit) and 16KiB RAM(for minimum memory model). BIOS and Microsoft BASIC was stored in ROM. 

When power on, BIOS processes "POST"(Power On Self Test) procedure, and after, call INT 19h. 
In INT 19h handler, BIOS checks that PC has any of floppy/hard/fixed diskette or not have. 
If PC has any of available diskkete, BIOS loads a first sector(512B) of diskette into 0x7C00. 

Now, you understand why you couldn't find out this magic number in x86 documents. This magic number belongs to BIOS specification. 

##The origin of 0x7C00

Stories surrounding IBM PC DOS, Microsoft, and SCP's 86-DOS are famous stories. See: "A Short History of MS-DOS". 

SCP's "86-DOS"(at 1980) is the reference OS for IBM PC DOS 1.0. 
86-DOS(early called "QDOS") is CP/M compatible OS for 8086/8088 cpu. At 1979, Digital Research Inc didn't have developed CP/M for 8086/8088 cpu yet. 
SCP sold two S-100 bus board, one is 8086 CPU board, two is "CPU Monitor" rom board. 
"CPU Monitor" program provided bootloader and debugger. This "CPU Monitor" bootloader loaded MBR into "0x200", NOT "0x7C00". In 1981, IBM PC DOS was the NEXT CP/M like OS for 8086/8088. 
So, I told you that "0x7C00 FIRST appeared in IBM PC 5150 ROM BIOS". 
Previous one, SCP's CPU Monitor bootloader loads into 0x200, not 0x7C00. 

##Why that CPU Monitor's bootloader loeded MBR into "0x200" ?

There're THREE reasons about "0x200". 

- 8086 Interrupts Vector use 0x0 - 0x3FF.
- 86-DOS was loaded from 0x400.
- 86-DOS didn't use interrupts vectors between 0x200 - 0x3FF.

These reasons mean 0x200 - 0x3FF needed to be reserved and couldn't be in the way of an OS, no matter where 86-DOS or user application wanted to load. 
So Tim Paterson (86-DOS developer) chose 0x200 for MBR load address. 

##Q:Who decided "0x7C00" ? - A: IBM PC 5150 BIOS Developer Team.

"0x7C00" was decided by IBM PC 5150 BIOS developer team (Dr. David Bradley). 
As mentioned above, this magic number was born at 1981 and "IBM PC/AT Compat" PC/BIOS vendors did not change this value for BIOS and OS's backward compatibility. 

Not Intel(8086/8088 vendor) nor Microsoft(OS vendor) decided it. 

##Q:What "0x7C00 = 32KiB - 1024B" means ? A: Affected by OS requirements and CPU memory layout.

IBM PC 5150 minimum memory model had only 16KiB RAM. So, you may have a question. 

> "Could minimum memory model (16KiB) load OS from diskette ? BIOS loads MBR into 32KiB - 1024B address, but physical RAM is not enough..." 

No, that case was out of consideration. One of IBM PC 5150 ROM BIOS Developer Team Members, Dr. David Bradley says: 

> "DOS 1.0 required a minimum of 32KB, so we weren't concerned about attempting a boot in 16KB." 

(Note: DOS 1.0 required 16KiB minimum ? or 32KiB ? I couldn't find out which correct. But, at least, in 1981's early BIOS development, they supposed that 32KiB is DOS minimum requirements.) 

BIOS developer team decided 0x7C00 because: 

- They wanted to leave as much room as possible for the OS to load itself within the 32KiB.
- 8086/8088 used 0x0 - 0x3FF for interrupts vector, and BIOS data area was after it.
- The boot sector was 512 bytes, and stack/data area for boot program needed more 512 bytes.
- So, 0x7C00, the last 1024B of 32KiB was chosen.

Once OS loaded and started, boot sector is never used until power reset. So, OS and application can use the last 1024B of 32KiB freely. 

After OS loaded, memory layout will be: 
```
+--------------------- 0x0
| Interrupts vectors
+--------------------- 0x400
| BIOS data area
+--------------------- 0x5??
| OS load area
+--------------------- 0x7C00
| Boot sector
+--------------------- 0x7E00
| Boot data/stack
+--------------------- 0x7FFF
| (not used)
+--------------------- (...)
```

That are the origin and reasons of "0x7C00", the magic number survived for about three decades in PC/AT Compat BIOS INT 19h handler. 