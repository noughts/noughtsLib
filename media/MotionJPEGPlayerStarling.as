/*

HOW TO USE

var mpegPlayer:MotionJPEGPlayerStarling = new MotionJPEGPlayerStarling( 320, 240, 10 );
mpegPlayer.width = 1024;
mpegPlayer.height = 768;


stage.addChild( mpegPlayer )
mpegPlayer.loadFile( "test.avi" ),


*/



package jp.noughts.media{

	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import flash.events.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import mx.utils.*;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;import org.osflash.signals.natives.base.*;
	import flash.filesystem.*;


	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import starling.display.*;
	import starling.textures.*;


	public class MotionJPEGPlayerStarling extends Sprite{


		public var complete_sig:Signal = new Signal();

		private var timer:SignalTimer;


		private var fileStream:FileStream;
		private var buffer : ByteArray = new ByteArray();
		private var _start:int = 0; //marker for start of jpg
		private var loader:Loader = new Loader();
		private var frames:Vector.<ByteArray> = new Vector.<ByteArray>();
		private var currentFrame:uint = 0;
		private var fileLoaded:Boolean = false;// ファイルの読み込みが完了したか？
		private var screen_bd:BitmapData;
		private var showFrameStartTime:uint;
		private var frameWait:uint;
		private var useFrames:Boolean
		private var loopCounter:uint = 0;

		private var texture:Texture;
		private var image:Image;


		// useFrames が true の時は、{$fps}フレームごとに1枚すすめる
		public function MotionJPEGPlayerStarling( $width:uint, $height:uint, $fps:uint, $useFrames:Boolean=false ){
			useFrames = $useFrames;
			if( useFrames ){
				frameWait = $fps;
			} else {
				frameWait = 1000 / $fps;
			}
			screen_bd = new BitmapData( $width, $height, true, 0 )


			fileStream = new FileStream();
		}



		public function loadFile( file:File, continuousMode:Boolean=false ){
			// 初期化
			currentFrame = 0;
			buffer.length = 0
			buffer.position = 0
			_start = 0
			fileStream.close();
			// 連続再生モードの時は、一回一回表示をクリアしないようにする
			if( continuousMode == false ){
				clearScreen()
			}



			// 読み込みモードで開く（同期）
			Logger.info("file load start")
			fileStream.open(file , FileMode.READ);
			fileStream.position = 0;
			fileStream.readBytes( buffer, 0, file.size )
			fileStream.close()
			Logger.info("file load end",buffer.length)


			var parser:MotionJPEGParser = new MotionJPEGParser( buffer )
			frames = parser.getImageBinaries()



			
			loopCounter = 0;
			CastDocument.stage.addEventListener( Event.ENTER_FRAME, _loop );
			loader.contentLoaderInfo.addEventListener( Event.COMPLETE, _onLoaderLoadComplete );

			if( useFrames==false ){
				_showFrame();
			}
		}



		public function clearScreen():void{
			screen_bd.fillRect( screen_bd.rect, 0 );
		}


		public function stop():void{
			CastDocument.stage.removeEventListener( Event.ENTER_FRAME, _loop );
			loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, _onLoaderLoadComplete );
		}


		private function _loop(e:Event):void{
			if( useFrames ){
				if( loopCounter % frameWait == 0 ){
					_showFrame()
				}
				loopCounter++
			}
		}


		private function _showFrame(){
			if( currentFrame>=frames.length ){
				Logger.info( "再生中バッファ待ちです。", currentFrame, frames.length )
				setTimeout( _showFrame, 10 )
				return;
			}

			showFrameStartTime = getTimer();
			loader.loadBytes( frames[currentFrame] );
		}



		private function _onLoaderLoadComplete(e:Event):void{
			screen_bd.draw( loader )


			texture = Texture.fromBitmapData( screen_bd, false );
			if( image ){
				image.texture = texture
			} else {
				image = new Image( texture );
				image.width = 1024;
				image.height = 768;
				addChild( image )
			}


			// フレームバッファクリア
			frames[currentFrame].length = 0
			loader.unload()

			currentFrame++;

			if( currentFrame>=frames.length ){
				trace( "再生完了!" )
				stop()
				complete_sig.dispatch();
				return;
			}

			
			if( useFrames ){
			} else {
				var _processTime:uint = getTimer() - showFrameStartTime;
				var _wait:int = frameWait - _processTime;
				if( _wait < 0 ){
					_wait = 0;
				}
				Logger.info( "processTime="+ _processTime +" wait="+ _wait )
				setTimeout( _showFrame, _wait )
			}
		}








	}
}