/*

ローカルキャッシュ付き LoadBitmap	

*/
package jp.noughts.progression.commands {
	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;import org.osflash.signals.natives.base.*;

	import flash.display.*;
	import flash.errors.IOError;
	import flash.events.*;
	import flash.net.*;
	import flash.system.LoaderContext;
	import jp.progression.commands.Command;
	import jp.progression.core.ns.progression_internal;
	import jp.progression.data.Resource;
	import jp.noughts.air.*
	
	/**
	 * <span lang="ja">LoadBitmap クラスは、指定された画像ファイルの読み込み操作を行うコマンドクラスです。</span>
	 * <span lang="en"></span>
	 * 
	 * @example <listing version="3.0">
	 * // LoadBitmap インスタンスを作成する
	 * var com:LoadBitmap = new LoadBitmap();
	 * 
	 * // コマンドを実行する
	 * com.execute();
	 * </listing>
	 */
	public class LoadBitmap extends LoadCommand {
		
		/**
		 * <span lang="ja">ポリシーファイルの存在の確認や、ApplicationDomain 及び SecurityDomain の設定を行う LoaderContext を取得または設定します。
		 * コマンド実行中に値を変更しても、処理に対して反映されません。</span>
		 * <span lang="en"></span>
		 */
		public function get context():LoaderContext { return _context; }
		public function set context( value:LoaderContext ):void { _context = value; }
		private var _context:LoaderContext;
		
		/**
		 * Loader を取得します。
		 */
		private var _loader:Loader;
		private var _urlLoader:URLLoader
		
		
		
		
		
		/**
		 * <span lang="ja">新しい LoadBitmap インスタンスを作成します。</span>
		 * <span lang="en">Creates a new LoadBitmap object.</span>
		 * 
		 * @param request
		 * <span lang="ja">読み込みたい JPEG、GIF、または PNG ファイルの絶対 URL または相対 URL です。</span>
		 * <span lang="en"></span>
		 * @param initObject
		 * <span lang="ja">設定したいプロパティを含んだオブジェクトです。</span>
		 * <span lang="en"></span>
		 */
		public function LoadBitmap( request:URLRequest, initObject:Object = null ) {
			// クラスをコンパイルに含める
			progression_internal;
			
			// 親クラスを初期化する
			super( request, initObject );
			cacheAsResource = true
			preventCache = false;
			// initObject が LoadBitmap であれば
			var com:LoadBitmap = initObject as LoadBitmap;
			if ( com ) {
				// 特定のプロパティを継承する
				_context = com._context;
			}
		}
		
		
		
		
		
		/**
		 * @private
		 */
		override protected function executeFunction():void {
			// メモリキャッシュを取得する
			var cache:Resource = Resource.progression_internal::$collection.getInstanceById( super.resId || super.request.url ) as Resource;
			
			// メモリキャッシュを破棄するのであれば
			if ( super.preventCache && cache is Resource && cache.data ) {
				var bmp:BitmapData = cache.data as BitmapData;
				
				if ( bmp ) {
					bmp.dispose();
				}
				
				cache.dispose();
				cache = null;
			}
			
			// メモリキャッシュが存在すれば
			if ( cache is Resource ) {
				//Logger.info( "LoadBitmap メモリキャッシュがありました" )
				// データを保持する
				var bd:BitmapData = cache.data.bitmapData.clone();
				var _bmp:Bitmap = new Bitmap( bd )
				super.data = _bmp;
				
				// イベントを送出する
				super.dispatchEvent( new ProgressEvent( ProgressEvent.PROGRESS, false, false, cache.bytesTotal, cache.bytesTotal ) );
				
				// 処理を終了する
				super.executeComplete();
			} else {

				// ディスクキャッシュがあるか？
				var diskRes:DiskCacheResource = DiskCacheResource.getById( super.request.url )
				diskRes.fileLoadComplete_sig.addOnce( _onDiskCacheLoadComplete )
				diskRes.fileLoadFailed_sig.addOnce( _onDiskCacheLoadFailed )
			}
		}

		private function _onDiskCacheLoadComplete( diskRes:DiskCacheResource ){
			//Logger.info( "LoadBitmap ディスクキャッシュがありました" )
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener( Event.COMPLETE, _complete );
			_loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, _ioError );
			_loader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, _securityError );
			//_loader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, super.dispatchEvent );
			_context.checkPolicyFile = false
			_loader.loadBytes( diskRes.data, _context )
		}

		private function _onDiskCacheLoadFailed( diskRes:DiskCacheResource ){
			//Logger.info( "LoadBitmap キャッシュがないので新規読み込みを開始します" )
			_urlLoader = new URLLoader();
			_urlLoader.dataFormat = URLLoaderDataFormat.BINARY
			_urlLoader.addEventListener(Event.COMPLETE, _urlLoaderComplete);
			_urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, Logger.info);
			_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, Logger.info);
			_urlLoader.load( toProperRequest( super.request ) );
		}
		/**
		 * @private
		 */
		override protected function interruptFunction():void {
			// 読み込みを閉じる
			if ( _loader ) {
				_loader.close();
			}
			
			// 破棄する
			_destroy();
		}
		
		/**
		 * 破棄します。
		 */
		private function _destroy():void {
			if ( _loader ) {
				// イベントリスナーを解除する
				_loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, _complete );
				_loader.contentLoaderInfo.removeEventListener( IOErrorEvent.IO_ERROR, _ioError );
				_loader.contentLoaderInfo.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, _securityError );
				_loader.contentLoaderInfo.removeEventListener( ProgressEvent.PROGRESS, super.dispatchEvent );
				
				// 破棄する
				_loader.unload();
				_loader = null;
			}
		}
		
		/**
		 * <span lang="ja">保持しているデータを解放します。</span>
		 * <span lang="en"></span>
		 */
		override public function dispose():void {
			// 親のメソッドを実行する
			super.dispose();
			
			_context = null;
		}
		
		/**
		 * <span lang="ja">LoadBitmap インスタンスのコピーを作成して、各プロパティの値を元のプロパティの値と一致するように設定します。</span>
		 * <span lang="en">Duplicates an instance of an LoadBitmap subclass.</span>
		 * 
		 * @return
		 * <span lang="ja">元のオブジェクトと同じプロパティ値を含む新しい LoadBitmap インスタンスです。</span>
		 * <span lang="en">A new LoadBitmap object that is identical to the original.</span>
		 */
		override public function clone():Command {
			return new LoadBitmap( super.request, this );
		}
		
		
		
		/**
		 * URLLoader のデータが正常にロードされたときに送出されます。
		 */
		private function _urlLoaderComplete( e:Event ):void {
			//Logger.info( "URLLoader complete", _urlLoader.data.length )
			new DiskCacheResource( super.request.url, _urlLoader.data )

			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener( Event.COMPLETE, _complete );
			_loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, _ioError );
			_loader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, _securityError );
			_loader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, super.dispatchEvent );
			_context.checkPolicyFile = false
			_loader.loadBytes( _urlLoader.data, _context )
		}



		
		/**
		 * ディスクキャッシュデータが正常にロードされたときに送出されます。
		 */
		private function _complete( e:Event ):void {
			// 対象が Bitmap であれば
			try {
				// データを保持する
				super.data = Bitmap( _loader.content );
			}
			catch ( err:Error ) {
				// データを破棄する
				super.data = null;
				
				// 破棄する
				_destroy();
				
				// エラー処理を実行する
				super.throwError( this, err.message );
				return;
			}
			
			// 破棄する
			_destroy();
			
			// 処理を終了する
			super.executeComplete();
		}
		
		/**
		 * 入出力エラーが発生してロード処理が失敗したときに送出されます。
		 */
		private function _ioError( e:IOErrorEvent ):void {
			// データを破棄する
			super.data = null;
			
			// 破棄する
			_destroy();
			
			// エラー処理を実行する
			super.throwError( this, new IOError( e.text ) );
		}
		
		/**
		 * 
		 */
		private function _securityError( e:SecurityErrorEvent ):void {
			// データを破棄する
			super.data = null;
			
			// 破棄する
			_destroy();
			
			// エラー処理を実行する
			super.throwError( this, new SecurityError( e.text ) );
		}
	}
}
