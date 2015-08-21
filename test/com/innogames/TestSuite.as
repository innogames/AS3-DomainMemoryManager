// =================================================================================================
//
//	Domain Memory Manager
//	Copyright 2015 InnoGames GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package com.innogames
{


	import com.innogames.util.DomainMemoryTestCase;
	import mockolate.runner.MockolateRunner;

	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class TestSuite
	{
		MockolateRunner;
		public var domainMemory:DomainMemoryTestCase;


	}
}
