package jp.noughts.media{
	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import mx.utils.*;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;import org.osflash.signals.natives.base.*;

	import caurina.transitions.Tweener;
	import cocoaas3.Titanium.UI.*

	import flash.media.*;
	import flash.utils.*;
	import flash.system.*;
	import flash.geom.*;
	import flash.display.JPEGEncoderOptions;
	import flash.display.Bitmap;
	import flash.display.BitmapData;

	import starling.core.*;
	import starling.display.*;
	import starling.events.*;
	import starling.textures.*;

	public class FinderStarling extends Sprite{


		public function get camera():Camera{ return _camera }

		private var _width:uint;
		private var _height:uint;
		private var _camera:Camera;
		private var _bd:BitmapData;
		private var _preview_bmp:Bitmap;
		private var _cameraId:String = "0";
		private var _texture:Texture;
		private var _image:Image;
		private var _buffer_bd:BitmapData;


		public function FinderStarling( $width:uint, $height:uint, cameraId:String=null ){
			_width = $width;
			_height = $height;

			//var _temp_texture:Texture = Texture.fromBitmapData( new BitmapData(1,1) )

			_buffer_bd = new BitmapData( _width, _height, false )

			Logger.info( Camera.names )
			if( cameraId ){
				_cameraId = cameraId;
			} else {
				_cameraId = String(Camera.names.length - 1);
			}
			_camera = Camera.getCamera( _cameraId );
			
			this.addEventListener( Event.ADDED_TO_STAGE, _onAddedToStage );
			this.addEventListener( Event.REMOVED_FROM_STAGE, _onRemovedFromStage );
		}


		private function _onAddedToStage( e ){
			Logger.info( "FinderStarling _onAddedToStage" )
			_initCamera()
			this.addEventListener( Event.ENTER_FRAME, _loop );
		}


		private function _onRemovedFromStage( e ){
			Logger.info( "FinderStarling _onRemovedFromStage" )
			this.removeEventListener( Event.ENTER_FRAME, _loop );
		}



		private function _initCamera():void{
			// カメラ設定 いじると、flvの再生時に不具合が起こるので慎重に！
			_camera.setMode( _width, _height, 30 );
			
			if( Capabilities.os.indexOf("iPhone")>-1 ){
			} else {
			}
		}


		private function _loop( e ){
			Logger.info(e)
			_camera.drawToBitmapData( _buffer_bd )
			_texture = Texture.fromBitmapData( _buffer_bd )
			if( _image ){
				_image.texture = _texture;
			} else {
				_image = new Image( _texture )
				addChild( _image )
			}
		}




		public function shutter():void{
			//_video.attachCamera( null );

			//_bd = new BitmapData( _width, _height );
			//_bd.draw( this );
			//_preview_bmp = new Bitmap( _bd );

			//removeChild( _video );
			//addChild( _preview_bmp );
		}



		public function getImageBinary( type:String="jpg", quality:uint=80 ):ByteArray{
			var ba:ByteArray = new ByteArray();
			_bd.encode( _bd.rect, new JPEGEncoderOptions(quality), ba );	
			return ba;		
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













	}

}
