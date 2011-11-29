﻿/* DashedLine classby Andy Woodruff (http://cartogrammar.com/blog || awoodruff@gmail.com)May 2008Still in progress; I'll get a more perfected version eventually. For now take it as is.This is a Sprite with the capability to do basic lineTo drawing with dashed lines.Example:	var dashy:DashedLine = new DashedLine(2,0x333333,new Array(3,3,10,3,5,8,7,13));	dashy.moveTo(120,120);	dashy.beginFill(0xcccccc);	dashy.lineTo(220,120);	dashy.lineTo(220,220);	dashy.lineTo(120,220);	dashy.lineTo(120,120);	dashy.endFill();This class was modified by kmonico to be used with Weave.*/package com.cartogrammar.drawing {		import flash.display.CapsStyle;	import flash.display.Graphics;	import flash.geom.Point;		/**	 * This class is an object which can draw dashed lines onto a graphics. To use this class	 * first set the graphics, lineStyle, and lengthsString.	 * @author Andy Woodruff (http://cartogrammar.com/blog || awoodruff@gmail.com) 	 *         with modifications by kmonico	 */		public class DashedLine {				private var _lengthsArray:Array = new Array();	// array of dash and gap lengths (dash,gap,dash,gap....). guaranteed to be length 2 * k for k an int		private var _lineColor:uint;	// line color		private var _lineWeight:Number;	// line weight		private var _lineAlpha:Number = 1;	// line alpha		private var _curX:Number = 0;	// stores current x as it changes with lineTo and moveTo calls		private var _curY:Number = 0;	// same as above, but for y		private var _remainingDist:Number = 0;	// stores distance between the end of the last full dash or gap and the end coordinates specified in lineTo		private var _curIndex:int;	// current index in the length array, so we know which dash or gap to draw		//private var _arraySum:Number = 0;	// total length of the dashes and gaps... not currently being used for anything, but maybe useful?		private var _startIndex:int = 0;	// array index (the particular dash or gap) to start with in a lineTo--based on the last dash or gap drawn in the previous lineTo (along with remainingDist, this is so our line can properly continue around corners!)		private var _continuouslyDashed:Boolean = true;		private var strokeGraphics:Graphics;		private var fillGraphics:Graphics;				public function get graphics():Graphics { return strokeGraphics; }		public function set graphics(g:Graphics):void { strokeGraphics = g; fillGraphics = g; }				public function get lengthsString():String { 			var s:String = '';			for (var i:int = 0; i < _lengthsArray.length - 1; ++i)			{				s += _lengthsArray[i].toString() + ',';			}			s += _lengthsArray[_lengthsArray.length - 1];			return s;		}		public function set lengthsString(csv:String):void { 			var parsedTokens:Array = csv.split(',');			_lengthsArray = [];			for each (var s:String in parsedTokens) {				_lengthsArray.push(int(s));			}						if (_lengthsArray.length % 2 == 1) // at least one value is non-zero				_lengthsArray.push(0);						if (_lengthsArray.length == 0)				_lengthsArray.push(DEFAULT_GAP_LENGTH, DEFAULT_LINE_LENGTH);		}				public function get lengthsArray():Array { return _lengthsArray.concat(); }		//public function set lengthsArray(a:Array):void { _lengthsArray = a; }				public function get lineColor():uint { return _lineColor; }		public function set lineColor(c:uint):void { lineColor = c; }				public function get lineWeight():Number { return _lineWeight; }		public function set lineWeight(c:Number):void { _lineWeight = c; }				public function get lineAlpha():Number{ return _lineAlpha; }		public function set lineAlpha(c:Number):void { _lineAlpha = c; }				public function get continuouslyDashed():Boolean { return _continuouslyDashed; }		public function set continuouslyDashed(b:Boolean):void { _continuouslyDashed = b; }				public static const DEFAULT_LINE_LENGTH:uint = 5;		public static const DEFAULT_GAP_LENGTH:uint = 5;				public function DashedLine(weight:int = 0, color:int = 0, graphics:Graphics = null) {						strokeGraphics = graphics;			fillGraphics = graphics;						// set line weight and color properties from constructor arguments			_lineWeight = weight;			_lineColor = color;		}		public function drawRect(xStart:Number, yStart:Number, width:Number, height:Number, corner:uint = TOP_LEFT):void		{			moveTo(xStart, yStart);						// go horizontal then vertical for 2 sides			switch (corner)			{				case TOP_LEFT:					lineTo(xStart + width, yStart);					lineTo(xStart + width, yStart + height);					break;				case TOP_RIGHT:					lineTo(xStart - width, yStart);					lineTo(xStart - width, yStart + height);					break;				case BOTTOM_LEFT:					lineTo(xStart + width, yStart);					lineTo(xStart + width, yStart - height);					break;				case BOTTOM_RIGHT:					lineTo(xStart - width, yStart);					lineTo(xStart - width, yStart - height);					break;			}						// reset			_startIndex = 0;			moveTo(xStart, yStart);						// go vertical then horizontal for 2 sides			switch (corner)			{				case TOP_LEFT:					lineTo(xStart, yStart + height);					lineTo(xStart + width, yStart + height);					break;				case TOP_RIGHT:					lineTo(xStart, yStart + height);					lineTo(xStart - width, yStart + height);					break;				case BOTTOM_LEFT:					lineTo(xStart, yStart - height);					lineTo(xStart + width, yStart - height);					break;				case BOTTOM_RIGHT:					lineTo(xStart, yStart - height);					lineTo(xStart - width, yStart - height);					break;			}		}		public static const TOP_LEFT:uint = 1;		public static const TOP_RIGHT:uint = 2;		public static const BOTTOM_LEFT:uint = 3;		public static const BOTTOM_RIGHT:uint = 4;				public function moveTo(x:Number,y:Number):void{			strokeGraphics.moveTo(x,y);	// move to specified x and y			fillGraphics.moveTo(x,y);			// keep track of x and y			_curX = x;				_curY = y;			// reset _remainingDist and startIndex - if we are moving away from last line segment, the next one will start at the beginning of the dash-gap sequence			_remainingDist = 0;			_startIndex = 0;		}				private function lengthsAllZero():Boolean {			for each (var num:uint in _lengthsArray)				if (num > 0) return false;							return true;		}		public function lineTo(x:Number,y:Number):void{			if (lengthsArray.length == 0 || lengthsAllZero())				this.lengthsArray.push(DEFAULT_GAP_LENGTH, DEFAULT_LINE_LENGTH);			var slope:Number = (y - _curY)/(x - _curX);	// get slope of segment to be drawn			// record beginning x and y			var startX:Number = _curX;			var startY:Number = _curY;			// positive or negative direction for each x and y?			var xDir:int = (x < startX) ? -1 : 1;			var yDir:int = (y < startY) ? -1 : 1;						if (!_continuouslyDashed) _startIndex = 0;						// keep drawing dashes and gaps as long as either the current x or y is not beyond the destination x or y			outerLoop : while (Math.abs(startX-_curX) < Math.abs(startX-x) || Math.abs(startY-_curY) < Math.abs(startY-y)){				// loop through the array to draw the appropriate dash or gap, beginning with _startIndex (either 0 or determined by the end of the last lineTo)				for (var i:int = _startIndex; i < _lengthsArray.length; i++){						var dist:Number = (_remainingDist == 0) ? _lengthsArray[i] : _remainingDist;	// distance to draw is either the dash/gap length from the array or _remainingDist left over from the last lineTo if there is any						// get increments of x and y based on distance, slope, and direction - see getCoords()						var xInc:Number = getCoords(dist,slope).x * xDir;						var yInc:Number = getCoords(dist,slope).y * yDir;						// if the length of the dash or gap will not go beyond the destination x or y of the lineTo, draw the dash or gap						if (Math.abs(startX-_curX) + Math.abs(xInc) < Math.abs(startX-x) || Math.abs(startY-_curY) + Math.abs(yInc) < Math.abs(startY-y)){							if (i % 2 == 0){	// if even index in the array, it is a dash, hence lineTo								strokeGraphics.lineTo(_curX + xInc,_curY + yInc);							} else {	// if odd, it's a gap, so moveTo								strokeGraphics.moveTo(_curX + xInc,_curY + yInc);							}							// keep track of the new x and y							_curX += xInc;							_curY += yInc;							_curIndex = i;	// store the current dash or gap (array index)							// reset _startIndex and _remainingDist, as these will only be non-zero for the first loop (through the array) of the lineTo							_startIndex = 0;							_remainingDist = 0;						} else {	// if the dash or gap can't fit, break out of the loop							_remainingDist = getDistance(_curX,_curY,x,y);	// get the distance between the end of the last dash or gap and the destination x/y							_curIndex = i;	// store the current index							break outerLoop;	// break out of the while loop						}				}			}						_startIndex = _curIndex;	// for next time, the start index is the last index used in the loop			if (_remainingDist != 0){	// if there is a remaining distance, line or move from current x/y to the destination x/y				if (_curIndex % 2 == 0){	// even = dash					strokeGraphics.lineTo(x,y);				} else {	// odd = gap					strokeGraphics.moveTo(x,y);				}				_remainingDist = _lengthsArray[_curIndex] - _remainingDist;	// remaining distance (which will be used at the beginning of the next lineTo) is now however much is left in the current dash or gap after that final lineTo/moveTo above			} else {	// if there is no remaining distance (i.e. the final dash or gap fits perfectly), we're done with the current dash or gap, so increment the start index for next time				if (_startIndex == _lengthsArray.length - 1){	// go to the beginning of the array if we're at the end					_startIndex = 0;				} else {					_startIndex++;				}			}			// at last, the current x and y are the destination x and y			_curX = x;			_curY = y;						fillGraphics.lineTo(x,y);	// simple lineTo (invisible line) on the fill shape so that the fill (if one was started via beginFill below) follows along with the dashed line		}				private function getCoords(distance:Number,slope:Number):Point {			var angle:Number = Math.atan(slope);	// get the angle from the slope			var vertical:Number = Math.abs(Math.sin(angle)*distance);	// vertical from sine of angle and length of hypotenuse - using absolute value here and applying negative as needed in lineTo, because this number doesn't always turn out to be negative or positive exactly when I want it to (haven't thought through the math enough yet to figure out why)			var horizontal:Number = Math.abs(Math.cos(angle)*distance);	// horizontal from cosine			return new Point(horizontal,vertical);	// return the point					}				private function getDistance(startX:Number,startY:Number,endX:Number,endY:Number):Number{			var distance:Number = Math.sqrt(Math.pow((endX-startX),2) + Math.pow((endY-startY),2));			return distance;		}				public function clear():void{			strokeGraphics.clear();			strokeGraphics.lineStyle(_lineWeight,_lineColor,_lineAlpha,false,"none",CapsStyle.NONE);			fillGraphics.clear();			moveTo(0,0);		}				public function lineStyle(w:Number=0,c:uint=0,a:Number=1):void{			_lineWeight = w;			_lineColor = c;			_lineAlpha = a;			strokeGraphics.lineStyle(_lineWeight,_lineColor,_lineAlpha,false,"none",CapsStyle.NONE);		}				public function beginFill(c:uint, a:Number=1):void{			fillGraphics.beginFill(c,a);		}		public function endFill():void{			fillGraphics.endFill();		}	}}