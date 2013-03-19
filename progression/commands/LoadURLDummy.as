/*

空のデータを読み込んだ時と同じ挙動をします。

*/
package jp.noughts.progression.commands {
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import jp.nium.core.debug.Logger;
	import jp.nium.core.L10N.L10NNiumMsg;
	import jp.progression.commands.Command;
	import jp.progression.core.ns.progression_internal;
	import jp.progression.data.Resource;
	import jp.progression.commands.net.*;
	
	/**
	 * <span lang="ja">LoadSound クラスは、指定された URL からデータの読み込み操作を行うコマンドクラスです。</span>
	 * <span lang="en"></span>
	 * 
	 * @example <listing version="3.0">
	 * // LoadURLDummy インスタンスを作成する
	 * var com:LoadURLDummy = new LoadURLDummy();
	 * 
	 * // コマンドを実行する
	 * com.execute();
	 * </listing>
	 */
	public class LoadURLDummy extends LoadCommand {
		
		/**
		 * <span lang="ja">読み込み操作に使用する URLLoader インスタンスを取得します。</span>
		 * <span lang="en"></span>
		 */
		public function get loader():URLLoader { return _loader; }
		private var _loader:URLLoader;
		
		/**
		 * <span lang="ja">ダウンロードしたデータがテキスト（URLLoaderDataFormat.TEXT）生のバイナリデータ（URLLoaderDataFormat.BINARY）、または URL エンコードされた変数（URLLoaderDataFormat.VARIABLES）のいずれであるかを制御します。</span>
		 * <span lang="en">Controls whether the downloaded data is received as text (URLLoaderDataFormat.TEXT), raw binary data (URLLoaderDataFormat.BINARY), or URL-encoded variables (URLLoaderDataFormat.VARIABLES).</span>
		 */
		public function get dataFormat():String { return _dataFormat; }
		public function set dataFormat( value:String ):void {
			switch ( value ) {
				case URLLoaderDataFormat.BINARY		:
				case URLLoaderDataFormat.TEXT		:
				case URLLoaderDataFormat.VARIABLES	: { _dataFormat = value; break; }
				default								: { throw new Error( Logger.getLog( L10NNiumMsg.getInstance().ERROR_003 ).toString( "dataFormat" ) ); }
			}
		}
		private var _dataFormat:String = URLLoaderDataFormat.TEXT;
		
		
		
		
		
		/**
		 * <span lang="ja">新しい LoadURLDummy インスタンスを作成します。</span>
		 * <span lang="en">Creates a new LoadURLDummy object.</span>
		 * 
		 * @param request
		 * <span lang="ja">読み込むファイルの絶対 URL または相対 URL を表す URLRequest インスタンスです。</span>
		 * <span lang="en"></span>
		 * @param initObject
		 * <span lang="ja">設定したいプロパティを含んだオブジェクトです。</span>
		 * <span lang="en"></span>
		 */
		public function LoadURLDummy( initObject:Object=null ) {
			// クラスをコンパイルに含める
			progression_internal;
			
			// 親クラスを初期化する
			super( new URLRequest(), null );
		}
		
		
		
		
		
		/**
		 * @private
		 */
		override protected function executeFunction():void {
			super.data = null;
			
			// イベントを送出する
			super.dispatchEvent( new ProgressEvent( ProgressEvent.PROGRESS, false, false, 0,0 ) );
			
			// 処理を終了する
			super.executeComplete();
		}
		
		/**
		 * @private
		 */
		override protected function interruptFunction():void {
			// 読み込みを閉じる
			try {
				_loader.close();
			}
			catch ( err:Error ) {}
			
			// 破棄する
			_destroy();
		}
		
		/**
		 * 破棄します。
		 */
		private function _destroy():void {
			if ( _loader ) {
				// イベントリスナーを解除する
				_loader.removeEventListener( Event.COMPLETE, _complete );
				_loader.removeEventListener( IOErrorEvent.IO_ERROR, _ioError );
				_loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, _securityError );
				_loader.removeEventListener( ProgressEvent.PROGRESS, super.dispatchEvent );
			}
		}
		
		/**
		 * <span lang="ja">保持しているデータを解放します。</span>
		 * <span lang="en"></span>
		 */
		override public function dispose():void {
			// 親のメソッドを実行する
			super.dispose();
		}
		
		/**
		 * <span lang="ja">LoadURLDummy インスタンスのコピーを作成して、各プロパティの値を元のプロパティの値と一致するように設定します。</span>
		 * <span lang="en">Duplicates an instance of an LoadURLDummy subclass.</span>
		 * 
		 * @return
		 * <span lang="ja">元のオブジェクトと同じプロパティ値を含む新しい LoadURLDummy インスタンスです。</span>
		 * <span lang="en">A new LoadURLDummy object that is identical to the original.</span>
		 */
		override public function clone():Command {
			return new LoadURLDummy( this );
		}
		
		
		
		
		
		/**
		 * 受信したすべてのデータがデコードされて URLLoader インスタンスの data プロパティへの保存が完了したときに送出されます。
		 */
		private function _complete( e:Event ):void {
			// データを保持する
			super.data = null
			
			// 破棄する
			_destroy();
			
			// 処理を終了する
			super.executeComplete();
		}
		
		/**
		 * URLLoader.load() の呼び出しによってセキュリティサンドボックスの外部にあるサーバーからデータをロードしようとすると送出されます。
		 */
		private function _securityError( e:SecurityErrorEvent ):void {
			// エラー処理を実行する
			super.throwError( this, new SecurityError( e.text ) );
		}
		
		/**
		 * URLLoader.load() の呼び出し時に致命的なエラーが発生してダウンロードが終了した場合に送出されます。
		 */
		private function _ioError( e:IOErrorEvent ):void {
			// エラー処理を実行する
			super.throwError( this, new IOError( e.text ) );
		}
	}
}
