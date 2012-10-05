package jp.noughts.media{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	import flash.media.*;
	import flash.geom.*;
	import caurina.transitions.Tweener;


	import jp.nium.core.debug.Logger;
	import cocoaas3.Titanium.UI.*


	public class Finder extends Sprite{

		private var _width:uint;
		private var _height:uint;
		private var _video:Video;
		private var _camera:Camera;
		private var _bd:BitmapData;
		private var _preview_bmp:Bitmap;
		private var _cameraId:String = "0";
		private var _flash_mc:Shape = new Shape();


		function Finder( $width:uint, $height:uint ){
			_width = $width;
			_height = $height;

			var g:Graphics = _flash_mc.graphics;
			g.beginFill( 0xffffff );
			g.drawRect( 0, 0, _width, _height );
			_flash_mc.visible = false;

			_camera = Camera.getCamera( _cameraId );
			_initCamera();

			addEventListener( Event.REMOVED_FROM_STAGE, _onRemovedFromStage );
		}

		private function _onRemovedFromStage( e ){
			removeEventListener( Event.REMOVED_FROM_STAGE, _onRemovedFromStage );
			_video.attachCamera( null );
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


		public function changeCamera():void{
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


		private function _initCamera(){
			if( _video ){
				removeChild( _video );
			}

			// カメラ設定 いじると、flvの再生時に不具合が起こるので慎重に！
			_camera.setMode( 320, 240, 15 );
			_camera.setQuality( 16384*3, 0 );

			var ratio:Number = 640 / 480;
			var frameSize:Rectangle = new Rectangle( 0, 0, _width, _height );
			var h:uint = frameSize.width;
			var w:uint = frameSize.width * ratio;
			_video = new Video( w, h );
			_video.rotation = 90;
			_video.x = frameSize.width;
			_video.y = frameSize.height/2 - w/2;
			_video.attachCamera( _camera );
			addChild( _video );
		}	













	}

}
