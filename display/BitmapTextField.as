﻿/*

var tfm:TextFormat = new TextFormat();
tfm.font = "_sans"
tfm.size = 32;
tfm.bold = true
var btf:BitmapTextField = new BitmapTextField( tfm )
btf.text = "hogeaaaaaaaaa"
stage.addChild( btf );



*/

package jp.noughts.display{

	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.display.*;
	import flash.geom.*;
	import flash.filters.BlurFilter;
	import flash.utils.*;

	public class BitmapTextField extends Sprite{

		static public  var stageObj:Stage;
		static private  var AA_MARGIN_WIDTH:Number = 16;// 生成するビットマップに多少の余白を持たせる
		static private  var AA_MARGIN_HEIGHT:Number = 16;// 
		static private  var AA_BMP_MAX_WIDTH:Number = 2800;// 生成するビットマップの最大サイズ
		static private  var AA_BMP_MAX_HEIGHT:Number = 2800;//
		static private  var AA_MAX_SCALE:Number = 3;// 最大拡大率
		static private  var AA_BLUR_STRENGTH:Number = 2;// ぼかしの強さ
		static private  var AA_BLUR_QUALITY:Number = 2;// ぼかしのクオリティ

		public var quality:uint = 1;
		private var _textField:TextField;

		// clone用
		private var _tfm:TextFormat;
		private var _textWidth:uint;
		private var _textHeight:uint;

		private var _bmp:Bitmap;
		//public function get bmp():Bitmap{ return _bmp }

		/*

		MEMO:

		「g」などの下部が欠けるときは、textWidth と textHeight を大きめに設定しましょう。
		最終的に無駄な部分はビットマップからはなくなるので問題ありません。

		*/

		public function BitmapTextField( tfm:TextFormat=null, textWidth:uint=0, textHeight:uint=0 ){
			_tfm = tfm;
			_textWidth = textWidth
			_textHeight = textHeight;

			_textField = new TextField();
			_textField.multiline = true
			if( textWidth == 0 ){
				_textField.autoSize = "left"
			} else {
				_textField.width = textWidth
			}
			if( textHeight != 0 ){
				_textField.height = textHeight
			}

			if( tfm ){
				if( tfm.font==null ){
					tfm.font = "Hiragino Kaku Gothic ProN"
				}
				_textField.defaultTextFormat = tfm;
			}
		}


		// 指定したサイズにscaleを調整する
		public function fit( $width:uint, $height:uint ):void{
			if( _bmp.width > $width ){
				_bmp.scaleX = $width / _bmp.width
			}
			if( _bmp.height > $height ){
				_bmp.scaleY = $height / _bmp.height
			}
		}



		public function set text( val:String ):void{
			_textField.text = val;
			update()
		}
		public function get text():String{
			return _textField.text;
		}

		public function set wordWrap( val:Boolean ):void{
			_textField.wordWrap = val;
		}
		public function set embedFonts( val:Boolean ):void{
			_textField.embedFonts = val
		}


		public function update():void{
			if( this.numChildren > 0 ){
				removeChildAt( 0 );
			}
			_bmp = getAAText()
			addChild( _bmp )
		}

		private function getAAText():Bitmap {
			if( quality==1 ){
				return simpleDraw();
			} else {
				return complexDraw();
			}
		}




		private function simpleDraw():Bitmap {
			if( _textField.text == "" ){
				return new Bitmap( new BitmapData(1,1) )
			}

			// 結果BitmapDataのサイズを取得
			// 中央ぞろえにしたときにバグるのを回避
			var my_fmt:TextFormat = _textField.getTextFormat();
			var aaWidth:Number;
			if (my_fmt["align"] == "center") {
				//var aaWidth:Number = _textField.width + AA_MARGIN_WIDTH;
				aaWidth = _textField.width;
			} else {
				aaWidth = (_textField.textWidth || _textField.width);
			}

			var aaHeight:Number = (_textField.textHeight || _textField.height) * 1.2;
			var bmpResult:BitmapData = new BitmapData (aaWidth, aaHeight, true, 0x00000000);
			bmpResult.draw( _textField )

			// 周りの透明部分をトリム
			var content_bd:BitmapData = trimWhiteSpace( bmpResult )

			// 後処理
			var bmp:Bitmap = new Bitmap( content_bd, "never", true );
			return bmp;
		}


		// BitmapData の周りの透明部分をトリムする
		private function trimWhiteSpace( source_bd:BitmapData ):BitmapData{
			var content_rect:Rectangle = source_bd.getColorBoundsRect( 0xFF000000, 0x00000000, false )
			trace(content_rect)

			var content_bd:BitmapData = new BitmapData( content_rect.width, content_rect.height, true, 0 )
			content_bd.copyPixels( source_bd, content_rect, new Point() )
			return content_bd;
		}




		private function complexDraw():Bitmap {
			// 結果BitmapDataのサイズを取得
			// 中央ぞろえにしたときにバグるのを回避
			var my_fmt:TextFormat = _textField.getTextFormat();
			var aaWidth:Number;
			if (my_fmt["align"] == "center") {
				//var aaWidth:Number = _textField.width + AA_MARGIN_WIDTH;
				aaWidth = _textField.width;
			} else {
				aaWidth = (_textField.textWidth || _textField.width);
			}
			//var aaHeight:Number = (_textField.textHeight || _textField._height) + AA_MARGIN_HEIGHT;
			var aaHeight:Number = (_textField.textHeight || _textField.height) * 1.2;

			// アンチエイリアス処理の設定
			var aaScale:Number = Math.min (AA_MAX_SCALE, Math.min (AA_BMP_MAX_WIDTH / aaWidth, AA_BMP_MAX_HEIGHT / aaHeight));
			var aaStrength:Number = AA_BLUR_STRENGTH;
			var aaQuality:Number = AA_BLUR_QUALITY;

			// 「拡大用BitmapData」と「結果用BitmapData」を準備
			var bmpCanvas:BitmapData = new BitmapData (aaWidth * aaScale, aaHeight * aaScale, true, 0x00000000);
			var bmpResult:BitmapData = new BitmapData (aaWidth, aaHeight, true, 0x00000000);

			// BESTクオリティでの描画を行うか？
			// AA(ぼかし)処理をFlash内部描画に任せます。
			// → ほとんどのサイズで綺麗だけど処理重いよ :-(
			var myMatrix:Matrix;
			var myColor:ColorTransform;
			if( quality==2 ){
				// 1.拡大描画
				myMatrix = new Matrix ();
				myMatrix.scale (aaScale,aaScale);
				bmpCanvas.draw (_textField,myMatrix,new ColorTransform (),null,null,true);

				// 2.ぼかし処理
				// ToDo:フォントサイズや用途でパラメータを弄る必要有
				var myFilter:BlurFilter = new BlurFilter (aaStrength, aaStrength, aaQuality);
				bmpCanvas.applyFilter (bmpCanvas,new Rectangle (0, 0, bmpCanvas.width, bmpCanvas.height),new Point (0, 0),myFilter);
				bmpCanvas.draw (_textField,myMatrix,new ColorTransform (),null,null,true);

				// 3.縮小描画
				myColor = new ColorTransform ();
				myColor.alphaMultiplier = 1.1;
				myMatrix.a = myMatrix.d = 1;
				myMatrix.scale (1 / aaScale,1 / aaScale);
				bmpResult.draw (bmpCanvas,myMatrix,myColor,null,null,true);
				bmpResult.draw (bmpCanvas,myMatrix,new ColorTransform (),null,null,true);
			} else {
				// 1.拡大描画
				myMatrix = new Matrix ();
				myMatrix.scale (aaScale,aaScale);
				bmpCanvas.draw (_textField,myMatrix,new ColorTransform (),null,null,true);

				// 2.縮小描画
				myColor = new ColorTransform ();
				myColor.alphaMultiplier = 1.3;
				myMatrix.a = myMatrix.d = 1;
				myMatrix.scale (1 / aaScale,1 / aaScale);
				bmpResult.draw (bmpCanvas,myMatrix,myColor,null,null,true);
			}

			// 後処理
			bmpCanvas.dispose ();

			//trace ("scale:" + aaScale + " time:" + (getTimer () - startTime));
			var bmp:Bitmap = new Bitmap( bmpResult, "never", true );
			return bmp;
		}


		public function clone():BitmapTextField{
			var btf:BitmapTextField = new BitmapTextField( _tfm, _textWidth, _textHeight )
			btf.text = this.text;
			return btf;
		}


	}
}










