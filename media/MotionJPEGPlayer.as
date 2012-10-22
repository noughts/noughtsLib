/*

HOW TO USE

var mpegPlayer:MotionJPEGPlayer = new MotionJPEGPlayer( 320, 240, 10 );
mpegPlayer.width = 1024;
mpegPlayer.height = 768;


stage.addChild( mpegPlayer )
mpegPlayer.loadFile( "test.avi" ),


*/



package jp.noughts.media{

	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import mx.utils.*;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;import org.osflash.signals.natives.base.*;
	import flash.filesystem.*;


	public class MotionJPEGPlayer extends Sprite{

		private var _signals:InteractiveObjectSignalSet;
		public function get signals():InteractiveObjectSignalSet{
			return _signals ||= new InteractiveObjectSignalSet(this);
		}

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



		// useFrames が true の時は、{$fps}フレームごとに1枚すすめる
		public function MotionJPEGPlayer( $width:uint, $height:uint, $fps:uint, $useFrames:Boolean=false ){
			useFrames = $useFrames;
			if( useFrames ){
				frameWait = $fps;
			} else {
				frameWait = 1000 / $fps;
			}
			screen_bd = new BitmapData( $width, $height, true, 0 )
			var screen_bmp:Bitmap = new Bitmap( screen_bd )
			screen_bmp.smoothing = true
			addChild( screen_bmp )

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
			this.addEventListener( Event.ENTER_FRAME, _loop );
			loader.contentLoaderInfo.addEventListener( Event.COMPLETE, _onLoaderLoadComplete );

			if( useFrames==false ){
				_showFrame();
			}
		}



		public function clearScreen():void{
			screen_bd.fillRect( screen_bd.rect, 0 );
		}


		public function stop():void{
			this.removeEventListener( Event.ENTER_FRAME, _loop );
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

			// フレームバッファクリア
			frames[currentFrame].length = 0
			loader.unload()

			currentFrame++;

			if( currentFrame>=frames.length ){
				trace( "再生完了!" )
				stop()
				dispatchEvent( new Event(Event.COMPLETE) )
				return;
			}

			
			if( useFrames ){
			} else {
				var _processTime:uint = getTimer() - showFrameStartTime;
				var _wait:int = frameWait - _processTime;
				if( _wait < 0 ){
					_wait = 0;
				}
				Logger.info( "wait="+ _wait )
				setTimeout( _showFrame, _wait )
			}
		}


		function FileIOErrorFunc(e:IOErrorEvent):void{
			trace("入出力エラー");
		}




		private function displayImage(image:ByteArray):void{
			dispatchEvent(new Event("videoReady"));
			loader.loadBytes(image);
		}






	}
}