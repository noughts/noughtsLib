package jp.noughts.media{
	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import mx.utils.*;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;import org.osflash.signals.natives.base.*;

	import caurina.transitions.Tweener;
	import cocoaas3.Titanium.UI.*


	public class Finder extends Sprite{

		static public const STAGE_VIDEO_MODE:String = "stageVideoMode"
		static public const NORMAL_VIDEO_MODE:String = "normalVideoMode"
		// stageVideoをそのまま表示させずに、一旦 bitmapData に draw して表示させるモード
		// スマホなど映像が回転してしまう場合にはこちら
		static public const STAGE_VIDEO_CAPTURE_MODE:String = "stageVideoCaptureMode"


		private var _signals:InteractiveObjectSignalSet;
		public function get signals():InteractiveObjectSignalSet{
			return _signals ||= new InteractiveObjectSignalSet(this);
		}

		public function get stageVideoMode():Boolean{ return _stageVideoMode }
		public function get camera():Camera{ return _camera }
		public function get bd():BitmapData{ return _bd }

		// ステージから削除された時に処理を止めるか？
		public var disableOnRemovedFromStage:Boolean = true;


		private var _stageVideoMode:Boolean = false;
		private var _mode:String
		private var _width:uint;
		private var _height:uint;
		private var _video:Video;
		private var _stageVideo:StageVideo
		private var _camera:Camera;
		private var _bd:BitmapData;
		private var _preview_bmp:Bitmap;
		private var _cameraId:String = "0";
		private var _flash_mc:Shape = new Shape();
		private var _initialized:Boolean = false;
		private var bmp:Bitmap;


		public function Finder( $width:uint, $height:uint, mode:String=NORMAL_VIDEO_MODE, cameraId:String=null ){
			_stageVideoMode = stageVideoMode;
			_mode = mode;
			_width = $width;
			_height = $height;

			_bd = new BitmapData( _width, _height );

			var g:Graphics = _flash_mc.graphics;
			g.beginFill( 0xffffff );
			g.drawRect( 0, 0, _width, _height );
			_flash_mc.visible = false;

			Logger.info( Camera.names )
			if( cameraId ){
				_cameraId = cameraId;
			} else {
				_cameraId = String(Camera.names.length - 1);
			}
			_camera = Camera.getCamera( _cameraId );
			

			signals.addedToStage.add( _onAddedToStage )
			signals.removedFromStage.add( _onRemovedFromStage )
		}


		private function _onAddedToStage( e ){
			Logger.info( "Finder _onAddedToStage" )
			// stageVideoチェック
			if( _mode==STAGE_VIDEO_MODE || _mode==STAGE_VIDEO_CAPTURE_MODE ){
				if( stage.stageVideos.length == 0 ){
					Logger.warn( "Finder StageVideo が利用できないので通常のvideoにフォールバックします。" )
					_mode = NORMAL_VIDEO_MODE
				}
			}
			_initCamera()
		}


		private function _initCamera():void{
			switch( _mode ){
				case STAGE_VIDEO_MODE:
					_setStageVideo()
					break;
				case STAGE_VIDEO_CAPTURE_MODE:
					_setStageVideoCapture()
					break;
				case NORMAL_VIDEO_MODE:
					_setNormalVideo();
					break;
			}
		}


		private function _onRemovedFromStage( e ){
			Logger.info( "Finder _onRemovedFromStage" )
			if( disableOnRemovedFromStage ){
				_video.attachCamera( null );
			}
			_stageVideo.attachCamera( null )
			removeEventListener( Event.ENTER_FRAME, _captureLoop )

		}





		private function _setStageVideoCapture():void{
			Logger.info( "stage.stageVideos", stage.stageVideos, stage.stageVideos.length )
			_stageVideo = stage.stageVideos[0];
			
			_camera.setMode( _width, _height, 30 );
			_stageVideo.attachCamera( _camera )

			bmp = new Bitmap( _bd )
			addChild( bmp )
			addEventListener( Event.ENTER_FRAME, _captureLoop )
		}


		private function _captureLoop( e ){
			_camera.drawToBitmapData( _bd )
		}



		private function _setStageVideo():void{
			Logger.info( "stage.stageVideos", stage.stageVideos, stage.stageVideos.length )
			_stageVideo = stage.stageVideos[0];
			_stageVideo.viewPort = new Rectangle( 0, 0, _width, _height );
			
			_camera.setMode( _width, _height, 60 );
			_stageVideo.attachCamera( _camera )
		}


		public function capture():void{
			_bd.draw( this );
			_preview_bmp = new Bitmap( _bd );
		}


		// capture してフラッシュアニメ
		public function shutter():void{
			capture()

			_flash_mc.visible = true;
			_flash_mc.alpha = 1;
			addChild( _flash_mc );
			Tweener.addTween( _flash_mc, {"_autoAlpha":0, time:0.66, transition:"easeInOutQuart"} );
		}



		public function getImageBinary( type:String="jpg", quality:uint=80 ):ByteArray{
			var ba:ByteArray = new ByteArray();
			_bd.encode( _bd.rect, new JPEGEncoderOptions(quality), ba );	
			return ba;		
		}




		public function reset():void{
			removeChild( _preview_bmp );
			addChild( _video );
			_video.attachCamera( _camera );
		}


		public function toggleCamera():void{
			switch( _cameraId ){
				case "0":
					_cameraId = "1"
					break;
				case "1":
					_cameraId = "0"
					break;
			}
			_camera = Camera.getCamera( _cameraId );
			_initCamera();			
		}

		public function changeToFrontCamera():void{
			if( _cameraId == "1"){
				return;
			}
			if( Camera.names.length == 1 ){
				return;
			}
			_cameraId = "1"
			_camera = Camera.getCamera( _cameraId );
			_initCamera();			
		}

		public function changeToBackCamera():void{
			if( _cameraId == "0"){
				return;
			}
			if( Camera.names.length == 1 ){
				return;
			}
			_cameraId = "0"
			_camera = Camera.getCamera( _cameraId );
			_initCamera();			
		}

		private function _setNormalVideo(){
			if( _initialized ){
				if( disableOnRemovedFromStage ){
					_video.attachCamera( _camera );
				}
				return;
			}

			if( _video ){
				removeChild( _video );
			}
			var standardRatio:Number = 1024/768;
			_video = new Video( _height*standardRatio, _height );
			_video.smoothing = true;
			
			// カメラ設定 いじると、flvの再生時に不具合が起こるので慎重に！
			_camera.setMode( 640*1.3333, 640, 30 );


			var frameSize:Rectangle = new Rectangle( 0, 0, _width, _height );
			
			if( Capabilities.os.indexOf("Mac")>-1 ){
				_video.x = 0 - (_video.width-_width)/2
			} else {
				_video.rotation = 90;
				_video.x = frameSize.width;
				_video.y = frameSize.height/2 - _video.width/2;
			}
			_video.attachCamera( _camera );
			addChild( _video );
			this.scrollRect = frameSize
			_initialized = true;
		}	













	}

}
