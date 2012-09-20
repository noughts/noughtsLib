/*

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
	import flash.utils.getTimer;

	public class BitmapTextField extends Sprite{

		static public  var stageObj:Stage;
		static private  var AA_MARGIN_WIDTH:Number = 16;// 生成するビットマップに多少の余白を持たせる
		static private  var AA_MARGIN_HEIGHT:Number = 16;// 
		static private  var AA_BMP_MAX_WIDTH:Number = 2800;// 生成するビットマップの最大サイズ
		static private  var AA_BMP_MAX_HEIGHT:Number = 2800;//
		static private  var AA_MAX_SCALE:Number = 3;// 最大拡大率
		static private  var AA_BLUR_STRENGTH:Number = 2;// ぼかしの強さ
		static private  var AA_BLUR_QUALITY:Number = 2;// ぼかしのクオリティ

		public var textWidth:uint;
		private var _textField:TextField;

		public function BitmapTextField( tfm:TextFormat=null, textWidth:uint=0 ){
			_textField = new TextField();
			if( textWidth == 0 ){
				_textField.autoSize = "left"
			} else {
				_textField.width = textWidth
			}

			if( tfm ){
				_textField.defaultTextFormat = tfm;	
			}
		}

		public function set text( val:String ):void{
			_textField.text = val;
			update()
		}

		public function set size( val:uint ):void{
			var format:TextFormat = new TextFormat();
			//format.font = "Verdana";
			//format.color = 0xFF0000;
			format.size = val;

			_textField.defaultTextFormat = format;		
			_textField.setTextFormat( format )	
			update()
		}


		public function update():void{
			if( this.numChildren > 0 ){
				removeChildAt( 0 );
			}
			var bmp:Bitmap = getAAText( false )
			addChild( bmp )
		}

		private function getAAText( bBest:Boolean=true ):Bitmap {
			var startTime:Number = getTimer ();

			// 結果BitmapDataのサイズを取得
			// 中央ぞろえにしたときにバグるのを回避
			var my_fmt:TextFormat = _textField.getTextFormat();
			var aaWidth:Number;
			if (my_fmt["align"] == "center") {
				//var aaWidth:Number = _textField.width + AA_MARGIN_WIDTH;
				aaWidth = _textField.width;
			} else {
				aaWidth = (_textField.textWidth || _textField.width) * 1.2;
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
			if (bBest) {

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

			} else {

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
			}

			// 後処理
			bmpCanvas.dispose ();

			//trace ("scale:" + aaScale + " time:" + (getTimer () - startTime));
			var bmp:Bitmap = new Bitmap(bmpResult, "never", true);
			return bmp;
		}
	}
}