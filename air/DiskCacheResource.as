package jp.noughts.air{

	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import mx.utils.*;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;import org.osflash.signals.natives.base.*;

	import flash.filesystem.*;
	//import jp.noughts.utils.*

	public class DiskCacheResource{

		static public var appId:String = "jp.dividual.blink";

		public var toBitmapComplete_sig:Signal = new Signal( Bitmap )
		public var fileLoadComplete_sig:Signal = new Signal( DiskCacheResource )
		public var fileLoadFailed_sig:Signal = new Signal( DiskCacheResource )

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
			var file:File = getFile( id )
			// file.exists は 2ms くらいかかってしまうので、
			// ここでファイルの存在を判定せずに、実際にロードして IO_ERROR がでるかどうかでファイルの存在をチェック

			//Logger.info( "DiskCacheResource", id +"のロードを開始します。" )
			var res:DiskCacheResource = new DiskCacheResource( id )
			res._data = new ByteArray()

			var stream:FileStream = new FileStream();
			var ioError:NativeSignal = new NativeSignal( stream, IOErrorEvent.IO_ERROR, IOErrorEvent )
			var complete:NativeSignal = new NativeSignal( stream, Event.COMPLETE, Event )
			ioError.addOnce( function(){
				stream.close ();
				res.fileLoadFailed_sig.dispatch( res )
			} )
			complete.addOnce( function(e:Event){
				ioError.removeAll()
				stream.readBytes( res._data, 0, stream.bytesAvailable );
				stream.close ();
				res.fileLoadComplete_sig.dispatch( res )
			} )
			stream.openAsync( file, FileMode.READ )
			return res
		}



		// 指定した id のファイルオブジェクトを返す
		static private function getFile( id:String ):File{
			var fileName:String = escapeMultiByte( id )
			var hash:uint =  _getStringHashNumber( fileName ) 
			var dirName1:String = String( hash ).substr( 0, 3 )
			var dirName2:String = String( hash )
			return File.userDirectory.resolvePath( "Library/Caches/"+ appId +"/resources/"+ dirName1 +"/"+ dirName2 +"/"+ fileName )
		}

		// 保存するファイルのフォルダを分散させるために、ファイル名文字列からハッシュを返す
		// MD5だと重いので、手動でやる
		static private function _getStringHashNumber( name_str:String ):uint{
			var len:uint = name_str.length;
			var out:uint = 0
			for( var i:int=0; i<len; i++ ){
				out += name_str.charCodeAt(i)
			}
			return out;
		}

	}
}





















