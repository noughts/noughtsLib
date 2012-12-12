/*

var tfm:TextFormat = new TextFormat();
tfm.font = "_sans"
tfm.size = 32;
tfm.bold = true
var btf:BitmapStageText = new BitmapStageText( tfm )
btf.text = "hogeaaaaaaaaa"
stage.addChild( btf );



*/

package jp.noughts.display{

	import flash.text.*;
	import flash.events.*;
	import flash.display.*;
	import flash.geom.*;
	import flash.utils.*;

	public class BitmapStageText extends Sprite{

		static public var sharedStage:Stage
		static private var singlelineStageText:StageText
		static private var multilineStageText:StageText
		private var bd:BitmapData
		private var bmp:Bitmap
		private var _width:uint

		public function BitmapStageText( $width:uint ){
			if( sharedStage==null ){
				throw new Error("sharedStageをせっていしてください");
			}

			_width = $width;
			if( singlelineStageText == null ){
				//var opt1:StageTextInitOptions = new StageTextInitOptions( false )
				//singlelineStageText = new StageText( opt1 )
				//singlelineStageText.fontSize = 32
				var opt2:StageTextInitOptions = new StageTextInitOptions( true )
				multilineStageText = new StageText( opt2 )
				multilineStageText.fontSize = 32
				multilineStageText.visible = false
			}

		}

		public function set color( val:uint ):void{
			multilineStageText.color = val;
		}
		public function set fontWeight( val:String ):void{
			multilineStageText.fontWeight = val;
		}


		public function set text( val:String ):void{
			multilineStageText.text = val;
			update()
		}
		public function get text():String{
			return multilineStageText.text;
		}

		public function set fontSize( val:uint ):void{
			multilineStageText.fontSize = val;
		}

		public function update():void{
			this.removeChildren()

			var viewPort:Rectangle = new Rectangle( 0, 0, _width, 1024 )
			multilineStageText.viewPort = viewPort;
			multilineStageText.stage = sharedStage
			multilineStageText.text = this.text

			bd = new BitmapData( viewPort.width, viewPort.height, true, 0 )
			multilineStageText.drawViewPortToBitmapData( bd )
			bd = trimWhiteSpace( bd )
			bmp = new Bitmap( bd )
			addChild( bmp )
		}





		// BitmapData の周りの透明部分をトリムする
		private function trimWhiteSpace( source_bd:BitmapData ):BitmapData{
			var content_rect:Rectangle = source_bd.getColorBoundsRect( 0xFF000000, 0x00000000, false )
			trace(content_rect)

			var content_bd:BitmapData = new BitmapData( content_rect.width, content_rect.height, true, 0 )
			content_bd.copyPixels( source_bd, content_rect, new Point() )
			return content_bd;
		}






	}
}










