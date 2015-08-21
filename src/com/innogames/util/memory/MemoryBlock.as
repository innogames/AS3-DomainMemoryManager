// =================================================================================================
//	Domain Memory Manager
//	Copyright 2015 InnoGames GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
// =================================================================================================
package com.innogames.util.memory
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	/**
	 * The MemoryBlock class manages the positions of allocated memory that can be used with the opcodes of avm2.intrinsics.memory;
	 * Allocate a memory block from the currently assigned DomainMemory and read/write values via fast memory opcodes from memblock.position to memblock.lastPosition
	 * 
	 * Load opcodes:
	 *
	 * li8(position:int):int		- load  8 bit int
     * li16(position:int):int		- load 16 bit int
     * li32(position:int):int		- load 32 bit int
     * lf32(position:int):Number	- load 32 bit float
     * lf64(position:int):Number	- load 64 bit float
	 *
	 * Store opcodes:
	 * 
     * si8(value:int, position:int):void		- store  8 bit integer
     * si16(value:int, position:int):void		- store 16 bit integer
     * si32(value:int, position:int):void		- store 32 bit integer
     * sf32(value:Number, position:int):void	- store 32 bit float
     * sf64(value:Number, position:int):void	- store 64 bit float
	 *
	 * Sign Extend opcodes:
	 * 
     * sxi1(value:int):int	- sign extend a  1 bit value to 32 bits
     * sxi8(value:int):int	- sign extend an 8 bit value to 32 bits
     * sxi16(value:int):int	- sign extend a 16 bit value to 32 bits
	 * 
	 */
	public final class MemoryBlock
	{
		private var _position:uint;
		private var _length:uint;
		
		private var _domainMemory:DomainMemory;
		private var _prevBlock:MemoryBlock;
		private var _nextBlock:MemoryBlock;

		private var _type:uint = 0;
		
		/**
		 * Constructor for a MemoryBlock;
		 * Don't use the constructor directly; use DomainMemory.allocate() to reserve a memory block
		 * @param	domainMemory
		 * @param	offset
		 * @param	length
		 */
		public function MemoryBlock(domainMemory:DomainMemory, length:uint, type:uint)
		{
			_domainMemory 	= domainMemory;
			_length 		= length;
			_type			= type;
		}
		
		/**
		 * Assign the current domainMemory to enable it for fast read/write access
		 */
		[Inline] public final function assign():void
		{
			_domainMemory.assign();
		}
		
		/**
		 * Copys bytes of the MemoryBlock to a new bytearray
		 * @param	position
		 * @param	length if -1 the complete byteArray will be copied
		 * @param	targetByteArray if null a new byteArray will be created
		 * @param	targetOffset the offset where to start inserting the copy on the target
		 * @return
		 */
		public final function copyToByteArray(position:uint = 0, length:int = -1, targetByteArray:ByteArray = null, targetOffset:uint = 0):ByteArray
		{
			var copy:ByteArray = null;

			if (targetByteArray)
			{
				if (targetByteArray.endian != _domainMemory.byteArray.endian)
					throw new Error("endian type of source ByteArray has to be the same; use Endian.LITTLE_ENDIAN");
				copy = targetByteArray;
			}
			else
			{
				copy = new ByteArray();
				copy.endian = Endian.LITTLE_ENDIAN;
			}

			copy.position = 0;
			domainMemoryBytes.position = this.position + position;

			if(length != -1)
				copy.length = length;
			
			if(length == -1)
				domainMemoryBytes.readBytes(copy, targetOffset, _length);
			else
				domainMemoryBytes.readBytes(copy, targetOffset, length);
				
			return copy;
		}
		
		/**
		 * copies the data of the provided bytearray into this memoryblock
		 * @param	bytes the bytearray to copy the data from	
		 * @param	numBytes the number of bytes to copy; -1 means all available data
		 */
		public final function copyFromByteArray(bytes:ByteArray, numBytes:int = -1, sourcePosition:uint = 0):void
		{
			if (bytes.endian != _domainMemory.byteArray.endian)
				throw new Error("endian type of source ByteArray has to be the same; use Endian.LITTLE_ENDIAN");
				
			if (bytes.length > this.length)
			{
				if (numBytes > this.length || numBytes == -1)
					throw new Error("Error: Tried to copy a big memory block into a smaller one");
			}
			bytes.position = sourcePosition;

			var length:uint = (numBytes == -1) ? bytes.length : ((numBytes > bytes.bytesAvailable) ? bytes.bytesAvailable : numBytes);
			bytes.readBytes(_domainMemory.byteArray, position, length);
		}
		
		/**
		 * copies the data of the provided memoryblock into this memoryblock
		 * @param	memoryBlock the memoryblock to copy the data from	
		 * @param	numBytes the number of bytes to copy; -1 means all available data
		 */
		public final function copyFromMemoryBlock(memoryBlock:MemoryBlock, numBytes:int = -1):void
		{
			if (memoryBlock.length > this.length)
			{
				if (numBytes > this.length || numBytes == -1)
					throw new Error("Error: Tried to copy a big memory block into a smaller one");
			}
			
			if(numBytes == -1)
				numBytes = memoryBlock._length;

			domainMemoryBytes.position = memoryBlock.position;
			domainMemoryBytes.readBytes(domainMemoryBytes, position, numBytes);
		}
		
		/**
		 * Returns a string representation of the object
		 * @return
		 */
		[Inline] public final function toString():String
		{
			return "[MemoryBlock offset: ".concat(position).concat(" , length: ").concat(_length).concat("]");
		}
		
		/**
		 * frees the memoryblock in the domainmemory and disposes it afterwards
		 */
		[Inline] public final function free():void
		{
			_domainMemory.free(this);
		}
		
		[Inline] internal final function applyPosition():void
		{
			if(type == MemoryBlockType.TYPE_STATIC)
			{
				_position = _prevBlock ? _prevBlock.lastPosition + 1 : 0;
			}
			else if(type == MemoryBlockType.TYPE_STACK)
			{
				_position = ((_prevBlock ? (_prevBlock.position) : _domainMemory.totalBytes) - _length);
			}
		}
		
		/**
		 * clears the references and makes the memoryblock unusable
		 */
		[Inline] internal final function dispose():void
		{
			_domainMemory = null;
			_position = 0;
			_length = 0;
		}
		
		//Getters & Setters
		
		/**
		 * Take care manipulating the bytes; memoryblock starts at position and ends on lastPosition
		 */
		[Inline] internal final function get domainMemoryBytes():FastBytes
		{
			return _domainMemory.byteArray;
		}
		
		[Inline] public final function get length():uint
		{
			return _length;
		}
		
		[Inline] public final function get lastPosition():uint
		{
			return position + _length - 1;
		}
		
		[Inline] internal final function get prevBlock():MemoryBlock
		{
			return _prevBlock;
		}
		
		[Inline] internal final function set prevBlock(value:MemoryBlock):void
		{
			_prevBlock = value;
			applyPosition();
		}
		
		[Inline] internal final function get nextBlock():MemoryBlock
		{
			return _nextBlock;
		}
		
		[Inline] internal final function set nextBlock(value:MemoryBlock):void
		{
			_nextBlock = value;
		}

		[Inline] public final function get type():uint
		{
			return _type;
		}
		
		[Inline] final public function get position():uint 
		{
			return _position;
		}
	}
}