// =================================================================================================
//	Domain Memory Manager
//	Copyright 2015 InnoGames GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
// =================================================================================================
package
{
	import com.innogames.TestSuite;
	import flash.display.Sprite;
	import org.flexunit.internals.TraceListener;
	import org.flexunit.listeners.CIListener;
	import org.flexunit.runner.FlexUnitCore;



	public class TestRunner extends Sprite
	{
		public function TestRunner()
		{
			var core:FlexUnitCore = new FlexUnitCore();
			core.addListener(new TraceListener());
			core.addListener(new CIListener());
			core.run(TestSuite);
		}

	}
}
