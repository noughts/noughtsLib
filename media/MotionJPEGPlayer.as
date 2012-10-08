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

		public function MotionJPEGPlayer( $width:uint, $height:uint, $fps:uint ){
			frameWait = 1000 / $fps;
			screen_bd = new BitmapData( $width, $height, true, 0 )
			var screen_bmp:Bitmap = new Bitmap( screen_bd )
			screen_bmp.smoothing = true
			addChild( screen_bmp )
			loader.contentLoaderInfo.addEventListener( Event.COMPLETE, _onLoaderLoadComplete );

			fileStream = new FileStream();
			fileStream.readAhead = 2048;
			fileStream.addEventListener(IOErrorEvent.IO_ERROR, FileIOErrorFunc);
			fileStream.addEventListener(ProgressEvent.PROGRESS, FileProgressFunc);
			fileStream.addEventListener(Event.COMPLETE, FileCompleteFunc);
		}



		public function loadFile( filePath:String, continuousMode:Boolean=false ){
			// 初期化
			currentFrame = 0;
			frames = new Vector.<ByteArray>();
			fileLoaded = false;
			fileStream.close();
			// 連続再生モードの時は、一回一回表示をクリアしないようにする
			if( continuousMode == false ){
				screen_bd.fillRect( screen_bd.rect, 0 );
			}


			Logger.info( "ファイルロード開始" )
			var file:File = File.documentsDirectory.resolvePath( filePath );

			// 読み込みモードで開く（非同期）
			fileStream.openAsync (file , FileMode.READ);

			_showFrame();
		}




		private function _showFrame(){
			if( fileLoaded==false && currentFrame>=frames.length ){
				Logger.info( "再生中バッファ待ちです。", currentFrame, frames.length )
				setTimeout( _showFrame, 10 )
				return;
			}

			showFrameStartTime = getTimer();
			loader.loadBytes( frames[currentFrame] );
		}

		private function _onLoaderLoadComplete(e:Event):void{
			screen_bd.draw( loader )

			currentFrame++;

			if( fileLoaded && currentFrame>=frames.length ){
				trace( "再生完了!" )
				//loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, _onLoaderLoadComplete );
				//fileStream.removeEventListener(IOErrorEvent.IO_ERROR, FileIOErrorFunc);
				//fileStream.removeEventListener(ProgressEvent.PROGRESS, FileProgressFunc);
				//fileStream.removeEventListener(Event.COMPLETE, FileCompleteFunc);
				dispatchEvent( new Event(Event.COMPLETE) )
				return;
			}
			var _processTime:uint = getTimer() - showFrameStartTime;
			var _wait:int = frameWait - _processTime;
			if( _wait < 0 ){
				_wait = 0;
			}
			Logger.info( "wait="+ _wait )
			setTimeout( _showFrame, _wait )
		}


		function FileIOErrorFunc(e:IOErrorEvent):void{
			trace("入出力エラー");
		}


		// 「メディア」から「読み込みバッファ」へ読み込み中に呼び出されるイベント
		function FileProgressFunc(e:ProgressEvent):void{
			//trace ("パーセント:" + Math.floor(e.bytesLoaded/e.bytesTotal*100));
			// 「読み込みバッファ」から「読み込み可能な分」を読み込む（同期実行）
			fileStream.readBytes( buffer ,buffer.length, fileStream.bytesAvailable );

			while(findImages()){
			    //donothing
			}
		}



		private function findImages():Boolean{
			var x:int = _start;
			var xpp:int;
			var startMarker:ByteArray = new ByteArray();	
			var end:int = 0;
			var image:ByteArray = new ByteArray();
			var newImageBuffer:ByteArray = new ByteArray();
			
			var len:int = buffer.length;
			var condition:int = len - 1;
			if (len > 1) {
				if(_start == 0){
					image.length = 0;
					//Check for start of JPG
					for (x; x < condition; ++x) {
						// get the first two bytes.
						buffer.position = x;
						buffer.readBytes(startMarker, 0, 2);
						
						//Check for end of JPG
						if (startMarker[0] == 255 && startMarker[1] == 216) {
							_start = x;
							startMarker.length = 0;
							break;					
						}
					}
				}
				for (x; x < condition; ++x) {
					// get the first two bytes.
					buffer.position = x;
					buffer.readBytes( startMarker, 0, 2 );
					if (startMarker[0] == 255 && startMarker[1] == 217){
						end = x;
						startMarker.length = 0
						//image = new ByteArray();TS
						buffer.position = _start;
						buffer.readBytes(image, 0, end - _start);
						
						//displayImage(image);
						// ByteArrayは参照コピーなので、クローンする
						var _ba:ByteArray = new ByteArray()
						_ba.writeBytes( image )
						frames.push( _ba )
						
						// truncate the buffer
						//var newImageBuffer:ByteArray = new ByteArray();TS
						
						buffer.position = end;
						buffer.readBytes(newImageBuffer, 0);
						buffer.length = 0
						buffer = newImageBuffer;
						newImageBuffer.length = 0
						newImageBuffer = null;	
						image.length = 0;
						
						_start = 0;
						x = 0;
						return true;
					}
				}
			}
			return false;
		}


		private function displayImage(image:ByteArray):void{
			dispatchEvent(new Event("videoReady"));
			loader.loadBytes(image);
		}


		// バッファへの読み込みが、ファイルの最後尾に到達した時に呼び出されるイベント
		function FileCompleteFunc(e:Event):void{
			Logger.info("バッファへの読み込みが、ファイルの最後尾に到達した")
			trace("読み込んだバイナリのサイズ:" + buffer.length)
			// ファイルストリームを閉じる
			fileStream.close ();
			fileLoaded = true;
		}



	}
}