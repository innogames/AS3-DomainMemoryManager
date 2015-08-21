// =================================================================================================
//	Domain Memory Manager
//	Copyright 2015 InnoGames GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
// =================================================================================================
package com.innogames.util.memory 
{
	/**
	 * Values for the MemoryBlockType
	 */
	public class MemoryBlockType 
	{
		/**
		 * A static typed MemoryBlock should be used for a consistent sized block that persists over a long time period
		 */
		public static const TYPE_STATIC:uint = 1;
		
		/**
		 * A stack typed MemoryBlock should be used for temporary accessed memory that doesn't need to persist in long term
		 */
		public static const TYPE_STACK:uint  = 2;
	}
}