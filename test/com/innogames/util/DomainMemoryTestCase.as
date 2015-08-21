// =================================================================================================
//	Domain Memory Manager
//	Copyright 2015 InnoGames GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
// =================================================================================================
package com.innogames.util
{
	
	import com.innogames.util.memory.DomainMemory;
	import com.innogames.util.memory.MemoryBlock;
	import com.innogames.util.memory.MemoryBlockType;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import mockolate.mock;

	import org.hamcrest.assertThat;
	import org.hamcrest.object.equalTo;
	
	import avm2.intrinsics.memory.*;

	/**
	 * Unit tests for the Domain Memory Manager
	 */
	[RunWith("mockolate.runner.MockolateRunner")]
	public class DomainMemoryTestCase
	{

		private var _domainMemory:DomainMemory


		[Before]
		public function setUp():void
		{
			_domainMemory = new DomainMemory(1024, true);
		}

		[Test]
		/**
		 * a simple allocate and measure size test
		 */
		public function allocateSingleBlockTest():void
		{	
			var memBlock:MemoryBlock = _domainMemory.allocate(512);
			assertThat(memBlock.length, equalTo(512));
			assertThat(_domainMemory.availableBytes, equalTo(512));
			memBlock.free();
		}
		
		[Test]
		/**
		 * This unit test allocates a memoryblock with cleanData:Boolean flag set to true;
		 * then we read the values again and check if all data is zeroed as expected
		 */
		public function allocateSingleBlockCleanTest():void
		{
			var memBlock:MemoryBlock = _domainMemory.allocate(512, MemoryBlockType.TYPE_STATIC, true);
			
			var position:uint = memBlock.position;
			var value:uint;
			
			while (position < memBlock.lastPosition)
			{
				value = li32(position += 4);
				assertThat(value, equalTo(0));
			}
			
			memBlock.free();
		}
		
		[Test]
		/**
		 * This unit test allocates a memoryblock and writes integer values into it;
		 * then we read the values again and check if all data is as expected
		 */
		public function writeReadSingleBlockTest():void
		{
			
			var memBlock:MemoryBlock = _domainMemory.allocate(512);
			
			var value:uint;
			var position:uint = memBlock.position;
			var currentIndex:uint = 0;
			
			while (position < memBlock.lastPosition)
			{
				si32(currentIndex++, position);
				position += 4
			}
			
			position = memBlock.position;
			currentIndex = 0;
			
			while (position < memBlock.lastPosition)
			{
				value = li32(position);
				position += 4
				assertThat(value, equalTo(currentIndex++));
			}

			memBlock.free();
		}
		
		[Test]
		/**
		 * This unit test allocates a memoryblock and writes integer values into it;
		 * after that a second block is created as copy of the first one;
		 * then we check if all data is as expected
		 * 
		 */
		public function allocateCopyTwoBlocksTest():void
		{
			
			var memBlock1:MemoryBlock = _domainMemory.allocate(512);
			var memBlock2:MemoryBlock;
			
			var value:uint;
			var position:uint = memBlock1.position;
			var currentIndex:uint = 0;
			
			while (position < memBlock1.lastPosition)
			{
				si32(currentIndex++, position);
				position += 4;
			}
			
			memBlock2 = _domainMemory.allocateCopy(memBlock1);
			position = memBlock2.position;
			currentIndex = 0;
			
			while (position < memBlock2.lastPosition)
			{
				value = li32(position);
				position += 4;
				assertThat(value, equalTo(currentIndex++));
			}

			memBlock1.free();
			memBlock2.free();
		}
		
		
		[Test]
		/**
		 * This unit test allocates a memoryblock and a bytearray;
		 * we fill the bytearray with values and copy it to the memoryblock
		 * then we check if all data is as expected
		 * 
		 */
		public function copyFromByteArrayTest():void
		{
			
			var byteArray:ByteArray = new ByteArray();
			byteArray.endian = Endian.LITTLE_ENDIAN;
			var value:uint;
			var position:uint = 0;
			var currentIndex:uint = 0;
			
			while (byteArray.length < 512)
			{
				byteArray.writeInt(currentIndex++);
			}
			
			var memBlock1:MemoryBlock = _domainMemory.allocate(512);
			memBlock1.copyFromByteArray(byteArray);
			
			position = memBlock1.position;
			currentIndex = 0;
			while (position < memBlock1.lastPosition)
			{
				value = li32(position);
				position += 4;
				assertThat(value, equalTo(currentIndex++));
			}
			memBlock1.free();

		}
		
		[Test]
		/**
		 * This unit test allocates a memoryblock and writes integer values into it;
		 * after that a second block is created as copy of the first one;
		 * the first one is freed and the second one should update it's position;
		 * then we check if all data is as expected
		 * 
		 */
		public function allocateDeleteTwoBlocksTest():void
		{
			
			var memBlock1:MemoryBlock = _domainMemory.allocate(512);
			var memBlock2:MemoryBlock;
			
			var value:uint;
			var position:uint = memBlock1.position;
			var currentIndex:uint = 0;
			
			while (position < memBlock1.lastPosition)
			{
				si32(currentIndex++, position);
				position += 4;
			}
			
			memBlock2 = _domainMemory.allocateCopy(memBlock1);
			memBlock1.free();
			
			position = memBlock2.position;
			currentIndex = 0;
			
			while (position < memBlock2.lastPosition)
			{
				value = li32(position);
				position += 4;
				assertThat(value, equalTo(currentIndex++));
			}

			
			memBlock2.free();
		}
		
		
		[Test]
		/**
		 * This unit test allocates a stack memoryblock and writes integer values into it;
		 * after that a second stack block is created as copy of the first one;
		 * 
		 */
		public function allocateStackTest():void
		{
			
			var memBlock1:MemoryBlock = _domainMemory.allocate(512, MemoryBlockType.TYPE_STACK);
			var memBlock2:MemoryBlock;
			
			var value:uint;
			var position:uint = memBlock1.position;
			var currentIndex:uint = 0;
			
			while (position < memBlock1.lastPosition)
			{
				si32(currentIndex++, position);
				position += 4;
			}
			
			memBlock2 = _domainMemory.allocateCopy(memBlock1, MemoryBlockType.TYPE_STACK);
			
			position = memBlock2.position;
			currentIndex = 0;
			
			while (position < memBlock2.lastPosition)
			{
				value = li32(position);
				position += 4;
				assertThat(value, equalTo(currentIndex++));
			}	
		}
		
		[Test]
		/**
		 * This unit test allocates a stack memoryblock and writes integer values into it;
		 * after that a second stack block is created as copy of the first one;
		 * then the first stack block is freed again;
		 * this is an unallowed operation so we check if an error is thrown as expected
		 * 
		 */
		public function freeStackTest():void
		{
			
			var memBlock1:MemoryBlock = _domainMemory.allocate(512, MemoryBlockType.TYPE_STACK);
			var memBlock2:MemoryBlock;
			
			var value:uint;
			var position:uint = memBlock1.position;
			var currentIndex:uint = 0;
			
			while (position < memBlock1.lastPosition)
			{
				si32(currentIndex++, position);
				position += 4;
			}
			
			memBlock2 = _domainMemory.allocateCopy(memBlock1, MemoryBlockType.TYPE_STACK);
			
			memBlock2.free();
			memBlock1.free();
			assertThat(_domainMemory.availableBytes, equalTo(_domainMemory.totalBytes));
		}
		
		[Test]
		/**
		 * This unit test allocates a stack memoryblock and writes integer values into it;
		 * after that a second stack block is created as copy of the first one;
		 * then the first stack block is freed again;
		 * this is an unallowed operation so we check if an error is thrown as expected
		 * 
		 */
		public function freeStackTest_Error():void
		{
			
			var memBlock1:MemoryBlock = _domainMemory.allocate(512, MemoryBlockType.TYPE_STACK);
			var memBlock2:MemoryBlock;
			
			var value:uint;
			var position:uint = memBlock1.position;
			var currentIndex:uint = 0;
			
			while (position < memBlock1.lastPosition)
			{
				si32(currentIndex++, position);
				position += 4;
			}
			
			memBlock2 = _domainMemory.allocateCopy(memBlock1, MemoryBlockType.TYPE_STACK);
			try
			{
				memBlock1.free();
			}
			catch (e:Error)
			{
				assertThat(e.message == "freed stack memoryblock before freeing upper stack memoryblocks");
			}
			
		}
		
		[Test]
		/**
		 * This unit test allocates several stack memoryblocks and clears the stack afterwards
		 */
		public function domainMemoryClearStackTest():void
		{
			
			while (_domainMemory.hasNumBytesAvailable(128))
			{
				_domainMemory.allocate(128, MemoryBlockType.TYPE_STACK);
			}
			
			assertThat(_domainMemory.availableBytes, equalTo(0));
			_domainMemory.clearStack();
			assertThat(_domainMemory.availableBytes, _domainMemory.totalBytes);
		}

		[After]
		public function tearDown():void
		{
			_domainMemory.dispose();
		}


	}
}
