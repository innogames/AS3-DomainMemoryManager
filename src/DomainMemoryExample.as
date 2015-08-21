// =================================================================================================
//	Domain Memory Manager
//	Copyright 2015 InnoGames GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
// =================================================================================================
package
{
	import com.innogames.util.memory.DomainMemory;
	import com.innogames.util.memory.MemoryBlock;
	import avm2.intrinsics.memory.*;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import avm2.intrinsics.memory.*;
	import flash.events.MouseEvent;
	import flash.globalization.NumberFormatter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	
	/**
	 * A quick example writing pixels each frame into an bitmapdata;
	 * switches the mode of the operation every 10 frames to compare the write speed
	 * and calculates an average time for each operation mode
	 */
	public class DomainMemoryExample extends Sprite 
	{
		private const MODE_VECTOR:String = "MODE VECTOR";
		private const MODE_BYTEARRAY:String = "MODE BYTEARRAY";
		private const MODE_DOMAIN_MEMORY:String = "MODE DOMAIN MEMORY";
		
		private const NUM_ITERATIONS:uint = 10;
		
		
		private var _domainMemory:DomainMemory;
		private var _memoryBlock:MemoryBlock;
		private var _bitmap:Bitmap;
		
		private var _bytes:ByteArray = new ByteArray();
		private var _vector:Vector.<uint> = new Vector.<uint>();
		
		private var _frameCounter:uint = 0;
		private var _mode:String = MODE_DOMAIN_MEMORY;
		
		private var _totalTimeByteArrayOperations:uint;
		private var _totalTimeDomainMemoryOperations:uint;
		private var _totalTimeVectorOperations:uint;
		
		private var _numByteArrayIterations:uint;
		private var _numDomainMemoryIterations:uint;
		private var _numVectorIterations:uint;
		
		private var _size:uint = 128;
		
		private var _numPixelsString:String;
		
		private var _outputTextField:TextField = new TextField();
		
		
		public function DomainMemoryExample() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var textFormat:TextFormat = new TextFormat("COURIER", 14, 0xFFFFFF);
			textFormat.leftMargin = textFormat.rightMargin = 10;
			
			_outputTextField.autoSize = TextFieldAutoSize.LEFT;
			_outputTextField.textColor = 0xFFFFFF;
			_outputTextField.backgroundColor = 0x000000;
			_outputTextField.background = true;
			_outputTextField.defaultTextFormat = textFormat;
			_outputTextField.selectable = false;
			
			_outputTextField.text = "CLICK TO START";
			addChild(_outputTextField);
		
			_bytes.endian = Endian.LITTLE_ENDIAN;
			
			stage.addEventListener(MouseEvent.CLICK, onClick);
			
		}
		
		private function reset():void 
		{
			if (!_domainMemory)
			{
				_domainMemory = new DomainMemory(_size * _size * 4, true);
			}
			else
			{
				_memoryBlock.free();
				_domainMemory.unassign();
				_domainMemory.setDomainMemorySize(_size * _size * 4);
				_domainMemory.assign();
			}
			
			_memoryBlock = _domainMemory.allocate(_size * _size * 4);
			
			if (!_bitmap)
			{
				_bitmap = new Bitmap(new BitmapData(_size, _size, true, 0x0));
				addChild(_bitmap);
				addChild(_outputTextField);
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			else
			{
				_bitmap.bitmapData.dispose();
				_bitmap.bitmapData = new BitmapData(_size, _size, true, 0x0);
			}
			
			var numberFormatter:NumberFormatter = new NumberFormatter("en");
			numberFormatter.fractionalDigits = 0;
			numberFormatter.groupingSeparator = ".";
			
			_numPixelsString = numberFormatter.formatUint(_size * _size);
			
			_numVectorIterations = 0;
			_numByteArrayIterations = 0;
			_numDomainMemoryIterations = 0;
			
			_totalTimeVectorOperations = 0;		
			_totalTimeByteArrayOperations = 0;
			_totalTimeDomainMemoryOperations = 0;
			
			_mode = MODE_DOMAIN_MEMORY;
			
		}
		
		private function onClick(e:MouseEvent):void 
		{
			_size *= 2;
			_size = _size > 4096 ? 256 : _size;
			reset();
		}
		
		private function onEnterFrame(e:Event):void 
		{
			_frameCounter++;
			if (_frameCounter % NUM_ITERATIONS == 1)
			{
				_mode = (_mode == MODE_VECTOR) ? MODE_BYTEARRAY : (_mode == MODE_BYTEARRAY) ? MODE_DOMAIN_MEMORY : MODE_VECTOR;
			}
			
			var frameStartTime:uint = getTimer();
			var counter:uint = _frameCounter;
			var position:uint;
			var endIndex:uint;
			var startIndex:uint;
			var numPixels:uint = _size * _size;
			const multiplier:uint = 255;
			
			if(_mode == MODE_VECTOR)
			{
				endIndex = numPixels;
				position = 0;
				
				_vector.length = 0;
				for (position;  position < endIndex; position++)
				{
					counter *= multiplier;
					_vector[position] = counter;
				}
				_bitmap.bitmapData.lock();
				_bitmap.bitmapData.setVector(_bitmap.bitmapData.rect, _vector);
				_bitmap.bitmapData.unlock();
				_numVectorIterations++;
				
			}
			else if(_mode == MODE_BYTEARRAY)
			{
				endIndex = numPixels;
				position = 0;
				_bytes.clear();
				for (position;  position < endIndex; position++)
				{
					counter *= multiplier;
					_bytes.writeInt(counter);
				}
				_bytes.position = 0;
				_bitmap.bitmapData.lock();
				_bitmap.bitmapData.setPixels(_bitmap.bitmapData.rect, _bytes);
				_bitmap.bitmapData.unlock();
				_numByteArrayIterations++;
				
			}
			else if (_mode == MODE_DOMAIN_MEMORY)
			{
				startIndex = _memoryBlock.position;
				endIndex = _memoryBlock.lastPosition;
				position = startIndex;
				for (position;  position < endIndex; position+=4)
				{
					counter *= multiplier;
					si32(counter, position);
				}
				_bitmap.bitmapData.lock();
				_bitmap.bitmapData.setPixels(_bitmap.bitmapData.rect, _memoryBlock.copyToByteArray(0, -1, _bytes));
				_bitmap.bitmapData.unlock();
				_numDomainMemoryIterations++;
			}
			
			var duration:uint = getTimer() - frameStartTime;
			_totalTimeVectorOperations += _mode == MODE_VECTOR ? duration : 0;
			_totalTimeByteArrayOperations += _mode == MODE_BYTEARRAY ? duration : 0;
			_totalTimeDomainMemoryOperations += _mode == MODE_DOMAIN_MEMORY ? duration : 0;
			
			_outputTextField.text = "\n" + _mode +"\n";
			_outputTextField.appendText("---------------------------------------------\n");
			_outputTextField.appendText("Currently filling " + _size +" x " + _size +" bitmap\nOperating on " + _numPixelsString +" pixels\nDuration: " + String(duration) +" ms\n");
			_outputTextField.appendText("---------------------------------------------\n");
			
			if(_numVectorIterations >= NUM_ITERATIONS)
				_outputTextField.appendText("Avg. Vector.<uint> operation time: " + (_totalTimeVectorOperations / _numVectorIterations).toFixed(2) + " ms\n");
				
			if(_numByteArrayIterations >= NUM_ITERATIONS)
				_outputTextField.appendText("Avg. ByteArray operation time: " + (_totalTimeByteArrayOperations / _numByteArrayIterations).toFixed(2) + " ms\n");
				
			if(_numDomainMemoryIterations >= NUM_ITERATIONS)
				_outputTextField.appendText("Avg. Domain Memory operation time: " + (_totalTimeDomainMemoryOperations / _numDomainMemoryIterations).toFixed(2) + " ms\n");
			
			_outputTextField.appendText("\n");
			
		}
		
	}
	
}