// =================================================================================================
//	Domain Memory Manager
//	Copyright 2015 InnoGames GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
// =================================================================================================
package com.innogames.util.memory
{

	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * The DomainMemory class is a helper class to get better overview of allowed memory usage;
	 * the domainMemory has to be assigned before usage
	 */
	public final class DomainMemory
	{
		/** The bytearray used by this DomainMemory instance*/
		private var _byteArray:FastBytes;

		/** headlink of the linked list */
		private var _firstBlock:MemoryBlock;

		/** taillink of the linked list*/
		private var _lastBlock:MemoryBlock;

		/** headlink of the stack linked list */
		private var _firstStackBlock:MemoryBlock;

		/** taillink of the stack linked list*/
		private var _lastStackBlock:MemoryBlock;
		
		/** the currently used bytes **/
		private var _bytesInUse:uint = 0;

		/** reference to the ApplicationDomain*/
		private static var _currentDomain:ApplicationDomain;

        /** bytearray with zeros as all values. Use this to copy to memoryblock if you want clean data**/
        private static var _zeroData:ByteArray = null;

		/**
		 * The DomainMemory class is a helper class to get better overview of allowed memory usage
		 * if you need fast read/write operations, allocate a memory block and use offset and size values from the memory block
		 * @param	numBytes sets the max. numBytes available in this DomainMemory; the value can't be changed after setting it once
		 * @param	autoAssign should the bytearray directly be assigned to the DomainMemory? if false you have to call assign() before fast read/write
		 */
		public function DomainMemory(numBytes:uint, autoAssign:Boolean)
		{
			_byteArray = new FastBytes(numBytes);
			_currentDomain = ApplicationDomain.currentDomain;

			if(_zeroData == null)
			{
				_zeroData 			= new ByteArray();
				_zeroData.endian 	= Endian.LITTLE_ENDIAN;
				_zeroData.length 	= 32 * 1024;
				_zeroData.position  = 0;

				while(_zeroData.position < _zeroData.length)
					_zeroData.writeByte(0);
			}

			_zeroData.position = 0;

			if (autoAssign)
				assign();

				
			//initially clean the complete memory by allocating a zeroed stack block
			var cleanDataBlock:MemoryBlock = allocate(_byteArray.length, MemoryBlockType.TYPE_STACK, true);
			cleanDataBlock.free();
		}

		/**
		 * Assign the current domainMemory to enable it for fast read/write access
		 */
		public function assign():void
		{
			assignMemory(this);
		}
		
		/**
		 * unassigns the current domain memory
		 */
		public function unassign():void
		{
			unassignMemory(this);
		}
				
		/**
		 * Returns a memory block as helper for fast read/write operations
		 *
		 * Note that you can either allocate a static or a stack memoryblock
		 * Use static if the allocated one will never be deallocated
		 * Use stack if the allocated one will be temporary. Note that they should be deleted at the end of the frame
		 * Stack memoryblocks have to be freed in the reversed order they where allocated
		 *
		 * @param numBytes the amount of bytes to allocate
		 * @param cleanData indicates if every bit of the allocated domainmemoryblock should be zeroed
		 * @param type can be either MemoryBlockType.TYPE_STATIC or MemoryBlockType.TYPE_STACK
		 *
		 * @return the allocated memoryblock with offset and size
		 */
		public final function allocate(numBytes:uint, type:uint = MemoryBlockType.TYPE_STATIC, cleanData:Boolean = false):MemoryBlock
		{
			var memoryBlock:MemoryBlock;

			if (_bytesInUse + numBytes <= _byteArray.length)
				memoryBlock = new MemoryBlock(this, numBytes, type);
			else
				throw new Error("not enough bytes available! Tried to allocated " + numBytes + " but only " + availableBytes + " bytes where available. Bytes in use: " + _bytesInUse);

			if(type == MemoryBlockType.TYPE_STATIC)
			{
				if (!_firstBlock)
					_firstBlock = memoryBlock;

				//add the new block to the chain
				if(_lastBlock)
					_lastBlock.nextBlock = memoryBlock;

				memoryBlock.prevBlock = _lastBlock;

				_lastBlock = memoryBlock;
			}
			else if(type == MemoryBlockType.TYPE_STACK)
			{
				if (!_firstStackBlock)
					_firstStackBlock = memoryBlock;

				//add the new block to the chain
				if(_lastStackBlock)
					_lastStackBlock.nextBlock = memoryBlock;

				memoryBlock.prevBlock = _lastStackBlock;

				_lastStackBlock = memoryBlock;
			}
			else
			{
				throw new Error("unrecognized MemoryBlockType");
			}

			// if you explicitely want to start with clean zeros in the bytes
			if(cleanData)
				cleanMemoryBlockData(memoryBlock);

			_bytesInUse += numBytes;

			return memoryBlock;
		}

		/**
		 * cleans data from memoryblock so it makes sure all bytes are 0x00
		 * this is necessary sometimes the memory isnt cleaned
		 *
		 * @param memoryBlock
		 */
		private function cleanMemoryBlockData(memoryBlock:MemoryBlock):void
		{
			var bytesLeft:int      = memoryBlock.length;
			var bytesToCopy:int    = 0;
			var bytePosition:int   = 0;

			while(bytesLeft)
			{
				bytesToCopy = (_zeroData.length < bytesLeft) ? _zeroData.length : bytesLeft;

				_zeroData.position = 0;
				_zeroData.readBytes(_byteArray, memoryBlock.position + bytePosition, bytesToCopy);

				bytePosition 	+= bytesToCopy;
				bytesLeft 		-= bytesToCopy;
			}
		}

		/**
		 * Allocates an exact copy of the given memoryblock
		 *
		 * See allocate() for more information
		 *
		 * @param memoryBlock the memoryblock to get a copy from
		 * @param type can be either MemoryBlock.TYPE_STATIC or MemoryBlock.TYPE_STACK
		 * @return the copy of the given memoryblock
		 */
		public final function allocateCopy(memoryBlock:MemoryBlock, type:uint = MemoryBlockType.TYPE_STATIC):MemoryBlock
		{
			var copy:MemoryBlock = allocate(memoryBlock.length, type);
			_byteArray.position = memoryBlock.position;
			_byteArray.readBytes(_byteArray, copy.position, copy.length);
			
			return copy;
		}

		/**
		 * Allocates an exact copy of the given bytearray
		 *
		 * See allocate() for more information
		 *
		 * @param byteArray the bytearray to get a copy from as a memoryblock
		 * @param type can be either MemoryBlock.TYPE_STATIC or MemoryBlock.TYPE_STACK
		 * @return the copy of the given bytearray
		 */
		public final function allocateCopyFromByteArray(byteArray:ByteArray, type:uint = MemoryBlockType.TYPE_STATIC, length:int = -1):MemoryBlock
		{
			if(length == -1)
				length = byteArray.length;

			var copy:MemoryBlock 	= allocate(length, type);
			byteArray.position 		= 0;
			byteArray.readBytes(_byteArray, copy.position, length);
			
			return copy;
		}

		/**
		 * Frees a memoryblock so the freed space in the bytearray can be used by new memoryblocks then
		 *
		 * Note that this operation is expensive if the memoryblock is a static one because all following memoryblocks
		 * will have to be realligned (copied) to prevent fragmentation
		 *
		 * @param memoryBlock the memoryblock to be freed
		 */
		public function free(memoryBlock:MemoryBlock):void
		{

			if(memoryBlock.type == MemoryBlockType.TYPE_STATIC)
			{
				if (memoryBlock == _firstBlock)
					_firstBlock = memoryBlock.nextBlock;

				if (memoryBlock.nextBlock)
				{
					var startPos:uint 	= memoryBlock.nextBlock.position;
					_byteArray.position = memoryBlock.position;
					_byteArray.writeBytes(_byteArray, startPos, _lastBlock.lastPosition - startPos);

					var nextBlock:MemoryBlock = memoryBlock.nextBlock;

					if (memoryBlock.prevBlock)
					{
						memoryBlock.prevBlock.nextBlock = memoryBlock.nextBlock;
						memoryBlock.nextBlock.prevBlock = memoryBlock.prevBlock;
						memoryBlock.prevBlock = null;
					}
					else
					{
						memoryBlock.nextBlock.prevBlock = null;
					}

					// update the position of the following memoryblocks after one got deleted
					while (nextBlock)
					{
						nextBlock.applyPosition();
						nextBlock = nextBlock.nextBlock;
					}

					memoryBlock.nextBlock = null;
				}
				else
				{
					if (memoryBlock.prevBlock)
						memoryBlock.prevBlock.nextBlock = null;

					_lastBlock = memoryBlock.prevBlock;
				}
			}
			else if(memoryBlock.type == MemoryBlockType.TYPE_STACK)
			{
				if(memoryBlock == _firstStackBlock)
					_firstStackBlock = memoryBlock.nextBlock;

				if (memoryBlock.prevBlock)
					memoryBlock.prevBlock.nextBlock = null;

				if(memoryBlock.nextBlock)
				{
					throw new Error("freed stack memoryblock before freeing upper stack memoryblocks");
				}

				_lastStackBlock = memoryBlock.prevBlock;
			}

			_bytesInUse -= memoryBlock.length;

			memoryBlock.dispose();
		}

		/**
		 * Clears the stack. 
		 * Should be called regularly to free up the domain memory from temporary memory blocks (stack) (for example on the beginning or end of a frame)
		 */
		public function clearStack():void
		{
			if (!_lastStackBlock) return;
			
			while(_lastStackBlock)
			{
				free(_lastStackBlock);
			}
		}

		/**
		 * Resizes the domain memory block;
		 * BEWARE: this can only be done if the domain memory is not assigned,
		 * their are no stack memory blocks and the new size isn't smaller then the bytes in use
		 * @param	numBytes the new size of the domain memory block
		 */
		public function setDomainMemorySize(numBytes:uint):void
		{
			if (isAssigned)
				throw new Error("Size of domainmemory can't be changed if it is assigned; unassign it first");
			if(_firstStackBlock)
				throw new Error("Size of domainmemory can't be changed if there is a block in the stack");
			
			if (_lastBlock && _bytesInUse > numBytes)
				throw new Error("Size of domainmemory can't be changed if the new size is smaller then the allocated size");
			
			_byteArray.resizeLength(numBytes);
		}

		public function enlargeToFreeBytes(numBytes:uint):void
		{
			var toBeAllocatedBytes:int = numBytes - availableBytes;

			if(toBeAllocatedBytes > 0)
			{
				setDomainMemorySize(_byteArray.length + toBeAllocatedBytes);
			}
		}
		
		//Getters & Setters
		
		/**
		 * the actual byteArray for internal usage
		 */
		internal final function get byteArray():FastBytes
		{
			return _byteArray;
		}
		
		/**
		 * Return the available bytes
		 *
		 * @return the available bytes that are free and can be used to create new memoryblocks on
		 */
		public final function get availableBytes():uint
		{
			return _byteArray.length - _bytesInUse;
		}

		/**
		 * The allocated number of bytes in total
		 *
		 * @return the bytes allocated by the domainmemory
		 */
		public final function get totalBytes():uint
		{
			return _byteArray.length;
		}

		/**
		 * returns how many bytes are currently in use by memoryblocks
		 */
		public final function get bytesInUse():uint
		{
			return _bytesInUse;
		}

		/**
		 * Checks if the given amount of bytes is free to use
		 * @param	numBytes
		 * @return boolean indicator if the numBytes are free
		 */
		public function hasNumBytesAvailable(numBytes:uint):Boolean
		{
			return availableBytes >= numBytes;
		}
		
		/**
		 * is the DomainMemory assigned to currentDomain.domainMemory?
		 */
		public final function get isAssigned():Boolean
		{
			return _currentDomain.domainMemory == _byteArray;
		}
		
		//Static
		/**
		 * Sets the current active domain memory
		 * @param	memory
		 */
		private static function assignMemory(memory:DomainMemory):void
		{
			if (_currentDomain.domainMemory != memory.byteArray)
			{
				_currentDomain.domainMemory = memory.byteArray;
			}
		}

		/**
		 * Unassigns the DomainMemory from the ApplicationDomain
		 * @param memory the DomainMemory to unassign
		 */
		private static function unassignMemory(memory:DomainMemory):void
		{
			if (_currentDomain.domainMemory == memory.byteArray)
			{
				_currentDomain.domainMemory = null;
			}
		}
		
		/**
		 * clears the domain memory and the all references to memoryblocks
		 * to prepare it to get garbage collected
		 */
		public function dispose():void 
		{
			unassign();
			var tmpMemoryBlock:MemoryBlock = _firstBlock;
			_firstBlock = null;
			_lastBlock = null;
			while (tmpMemoryBlock)
			{
				tmpMemoryBlock.dispose();
				tmpMemoryBlock = tmpMemoryBlock.nextBlock;
			}
			
			
			tmpMemoryBlock = _firstStackBlock;
			_firstStackBlock = null;
			_lastStackBlock = null;
			while (tmpMemoryBlock)
			{
				tmpMemoryBlock.dispose();
				tmpMemoryBlock = tmpMemoryBlock.nextBlock;
			}
			
			if (_zeroData)
			{
				_zeroData.clear();
				_zeroData = null;
			}
			
			_byteArray.clear();
			_byteArray = null;
		}
	}
}