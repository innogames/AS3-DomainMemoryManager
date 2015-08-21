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
	 * The FastBytes class represents a bytearray that is assigned
	 * to the systems ram to allow fast mem operations(avm2.intrinsics.memory);
	 * once assigned to the DomainMemory it can not change length and endian
	 */
	internal final class FastBytes extends ByteArray 
	{
		
		public function FastBytes(length:uint) 
		{
			super();
			super.length = Math.max(ApplicationDomain.MIN_DOMAIN_MEMORY_LENGTH, length);
			super.endian = Endian.LITTLE_ENDIAN;
		}
		
		public override function set endian(value:String):void 
		{
			throw new Error("The endian of DomainMemory can not be changed");
		}
		
		override public function set length(value:uint):void 
		{
			throw new Error("The length of DomainMemory can not be changed when assigned");
		}
		
		internal function resizeLength(newLength:uint):void
		{
			super.length = newLength;
		}
	}

}