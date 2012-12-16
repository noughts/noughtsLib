package jp.noughts.air{

	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import mx.utils.*;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;import org.osflash.signals.natives.base.*;

	import flash.filesystem.*;
	//import jp.noughts.utils.*

	public class DiskCacheResource{

		public var toBitmapComplete_sig:Signal = new Signal( Bitmap )

		private var _data:ByteArray;
		public function get data():ByteArray{ return _data }

		public function DiskCacheResource( id:String, $data:ByteArray=null ){
			if( $data ){
				_data = $data;
				var file:File = getFile( id )
				var stream:FileStream = new FileStream();
				stream.open( file , FileMode.WRITE );
				stream.writeBytes( data );
				stream.close ();
				Logger.info( "ディスクキャッシュ保存しました。", file.nativePath )
			}
		}


		public function toBitmap():void{
			var context:LoaderContext = new LoaderContext(); 
			context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD// パフォーマンス向上

			var loader_obj : Loader = new Loader();
			var info : LoaderInfo = loader_obj.contentLoaderInfo;
			info.addEventListener (Event.COMPLETE,LoaderInfoCompleteFunc);
			info.addEventListener (IOErrorEvent.IO_ERROR,LoaderInfoIOErrorFunc);
			loader_obj.loadBytes( _data, context );
		}
		private function LoaderInfoCompleteFunc (event : Event) {
			trace ("メモリストリームから読み込みに成功");
			var loader:Loader = event.target.loader;
			// Bitmapクラスに型変換
			var bmp:Bitmap = Bitmap( loader.content );
			toBitmapComplete_sig.dispatch( bmp )
		}
		private function LoaderInfoIOErrorFunc (event : IOErrorEvent) {
			trace ("ファイル入出力のエラー");
		}



		static public function getById( id:String ):DiskCacheResource{
			var res:DiskCacheResource = new DiskCacheResource( id )
			res._data = new ByteArray()

			var file:File = getFile( id )
			try{
				var stream:FileStream = new FileStream();
				stream.open( file , FileMode.READ );
				stream.readBytes( res._data, 0, file.size );
				stream.close ();
				return res
			} catch (e:Error){
				Logger.info( "ディスクキャッシュ読み込み失敗", file.nativePath, e )
			}
			return null
		}



		// 指定した id のファイルオブジェクトを返す
		static private function getFile( id:String ):File{
			//var fileName:String = escapeMultiByte( id )
			var fileName:String = MD5.encrypt( id )
			var dirName:String = fileName.substr( 0,2 )
			return File.userDirectory.resolvePath( "Library/Caches/"+ dirName +"/"+ fileName )
		}


	}
}