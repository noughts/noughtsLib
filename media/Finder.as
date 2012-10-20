package jp.noughts.media{
	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import mx.utils.*;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;import org.osflash.signals.natives.base.*;

	import caurina.transitions.Tweener;
	import cocoaas3.Titanium.UI.*


	public class Finder extends Sprite{

		private var _signals:InteractiveObjectSignalSet;
		public function get signals():InteractiveObjectSignalSet{
			return _signals ||= new InteractiveObjectSignalSet(this);
		}

		public function get stageVideoMode():Boolean{ return _stageVideoMode }
		public function get camera():Camera{ return _camera }

		private var _stageVideoMode:Boolean = false;
		private var _width:uint;
		private var _height:uint;
		private var _video:Video;
		private var _camera:Camera;
		private var _bd:BitmapData;
		private var _preview_bmp:Bitmap;
		private var _cameraId:String = "0";
		private var _flash_mc:Shape = new Shape();


		public function Finder( $width:uint, $height:uint, stageVideoMode:Boolean=false ){
			_stageVideoMode = stageVideoMode;
			_width = $width;
			_height = $height;

			var g:Graphics = _flash_mc.graphics;
			g.beginFill( 0xffffff );
			g.drawRect( 0, 0, _width, _height );
			_flash_mc.visible = false;

			_cameraId = String(Camera.names.length - 1);
			_camera = Camera.getCamera( _cameraId );
			

			signals.addedToStage.add( _onAddedToStage )
			signals.removedFromStage.add( _onRemovedFromStage )
		}


		private function _onAddedToStage( e ){
			// stageVideoチェック
			if( _stageVideoMode ){
				if( stage.stageVideos.length == 0 ){
					Logger.warn( "Finder StageVideoが利用できないので通常のvideoにフォールバックします。" )
					_stageVideoMode = false;
				}
			}
			_initCamera()
		}


		private function _initCamera():void{
			if( _stageVideoMode ){
				_setStageVideo()
			} else {
				_setNormalVideo();
			}

		}



		private function _onRemovedFromStage( e ){
			_video.attachCamera( null );
		}



		private function _setStageVideo():void{
			var stageVideo:StageVideo = stage.stageVideos[0];
			stageVideo.viewPort = new Rectangle( 0, 0, _width, _height );
			
			_camera.setMode( _width, _height, 60 );
			stageVideo.attachCamera( _camera )
		}





		public function getImageBinary( type:String="jpg" ):ByteArray{
			var ba:ByteArray = new ByteArray();
			_bd.encode( new Rectangle(0,0,290,290), new JPEGEncoderOptions(), ba );	
			return ba;		
		}

		public function shutter():void{
			_video.attachCamera( null );

			_bd = new BitmapData( _width, _height );
			_bd.draw( this );
			_preview_bmp = new Bitmap( _bd );

			removeChild( _video );
			addChild( _preview_bmp );

			// フラッシュアニメ
			_flash_mc.visible = true;
			_flash_mc.alpha = 1;
			addChild( _flash_mc );
			Tweener.addTween( _flash_mc, {"_autoAlpha":0, time:0.66, transition:"easeInOutQuart"} );
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


		private function _setNormalVideo(){
			if( _video ){
				removeChild( _video );
			}
			var standardRatio:Number = 1024/768;
			_video = new Video( _height*standardRatio, _height );
			_video.smoothing = true;
			
			// カメラ設定 いじると、flvの再生時に不具合が起こるので慎重に！
			_camera.setMode( 1024, 768, 30 );


			var frameSize:Rectangle = new Rectangle( 0, 0, _width, _height );
			
			if( Capabilities.os.indexOf("iPhone")>-1 ){
				_video.rotation = 90;
				_video.x = frameSize.width;
				_video.y = frameSize.height/2 - _video.width/2;
			} else {
				_video.x = 0 - (_video.width-_width)/2
			}
			_video.attachCamera( _camera );
			addChild( _video );
			this.scrollRect = frameSize
		}	













	}

}
