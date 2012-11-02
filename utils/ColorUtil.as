package jp.noughts.utils{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.geom.*;

	public class ColorUtil{


		// iOS の GPU モードにも対応しています。
		static public function setOffset( target:DisplayObject, red:int, green:int, blue:int ):void{
			var ct:ColorTransform = new ColorTransform();
			ct.redOffset = red;
			ct.greenOffset = green;
			ct.blueOffset = blue;
			target.transform.colorTransform = ct;

		}

	}

}