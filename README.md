# AS3-DomainMemoryManager
A manager for domain memory access in Adobe AIR/Flash.
This project is published under MIT License and can be used free of charge.


## What is Domain Memory?
Short: Domain Memory can be used to perform high-performance memory operations in Flash and AIR applications.
Formerly fast memory operations could only be used via Adobe Alchemy (nowadays known as FlasCC, the C/C++ Cross-Compiler for flash/AIR applications) or via external byte code optimizers like Apparat or Azoth or via Haxe.
If you are interested in history of fast memory operations in Flash, here are some additional links.

http://philippe.elsass.me/2010/05/as3-fast-memory-access-without-alchemy/

https://en.wikipedia.org/wiki/CrossBridge
## How can I use Domain Memory?
Using domain memory is really simple. A basic example can be found here:

http://www.adobe.com/devnet/air/articles/faster-byte-array-operations.html
## What is the Manager for?
DomainMemory usage has some issues:
- only one byte array can be assigned to the ApplicationDomain.domainMemory at the same time
- switching byte arrays on ApplicationDomain.domainMemory doesn't perform well

These issues are important if you want to work with several separate 'MemoryBlocks' that should be used in different places of the application.
Some tests revealed that working with domain memory performs best if there is only a single byte array and no switching.
This was the reason for starting to implement a manager that allows to allocate persistent memory blocks from the single byte array and that is able to manage free space, positions in the byte stream, defragmentation of the memory, etc.

![alt tag](DomainMemoryManager.png)

In the end, a memory block is nothing more then a helper object that returns a start and an end index for operations that should be performed on domain memory. There is no security check. This provides full performance for the memory operations but can be dangerous if not used carefully.
It can be used for high-performance operations on large amounts of data; for example for preparing vertex data for the GPU (byte arrays also upload faster then vectors)

## Example
```javascript
import com.innogames.util.memory.DomainMemory;
import com.innogames.util.memory.MemoryBlock;
import avm2.intrinsics.memory.*;
 
var domainMemory:DomainMemory = new DomainMemory(1024, true);
var memBlock1:MemoryBlock = domainMemory.allocate(512);
var memBlock2:MemoryBlock = domainMemory.allocate(512, MemoryBlockType.TYPE_STACK);
 
var startIndex:uint = memBlock2.position;
var endIndex:uint = memBlock2.lastPosition;
var position:uint = startIndex;
var value:uint = 1;
 
// fill up the transient stack memBlock2 with uint values
for (position;  position < endIndex; position+=4)
{    
    value *= 127; 
    si32(value, position);
}
 
// copy the values into persistent memBlock1
memBlock1.copyFromMemoryBlock(memBlock2);
 
startIndex = memBlock1.position;
endIndex = memBlock1.lastPosition;
position = startIndex;
 
// read the copied uint values back from memBlock2
for (position;  position < endIndex; position+=4)
{
    value = li32(position)
}
 
// clear the stack on the start or end of the frame;
// make sure that stack blocks are not used as persisent blocks (keep no reference on it)
domainMemory.clearStack();
```