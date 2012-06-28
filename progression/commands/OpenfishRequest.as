package jp.noughts.progression.commands{
	import flash.errors.*;
	import flash.net.*;
	import flash.events.*;
	import flash.utils.*;
	import jp.progression.commands.*;
	import jp.nium.core.debug.Logger;
	import jp.nium.utils.ObjectUtil;
	import jp.progression.core.PackageInfo;
	import com.cocoafish.sdk.Cocoafish;
	import flash.data.EncryptedLocalStore;
	import jp.noughts.utils.*;

	public class OpenfishRequest extends Command {
		
		static private var cocoafish;
		static public var baseUrl:String = "localhost:8080";
		private var _route:String
		private var _param:Object
		private var _method:String;

				
		public function OpenfishRequest( route:String, method:String, param:Object=null, initObject:Object = null ) {
			if( !cocoafish ){
				cocoafish = new Cocoafish( "appkey", "", baseUrl );
			}

			var udid:String = getUDID();

			_route = route;
			if( param ){
				_param = param;
				if( method == URLRequestMethod.POST ){
					_param.udid = udid;
				}
			} else {
				if( method == URLRequestMethod.POST ){
					_param = {udid: udid}
				}
			}
			
			_method = method;
			
			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, initObject );
		}
		

		// UDIDを取得
		// あればそのまま取得
		// なければ作成して、アプリ削除しても残るデータ領域に保存
		public function getUDID():String{
			var storedValue:ByteArray = EncryptedLocalStore.getItem('udid');
			if( storedValue ){
				return MD5.encrypt( storedValue.readUTFBytes(storedValue.length) );
			} else {
				// 作成して保存
				var now:Date = new Date();
				var udid:String = String( now.getTime() ) + String( Math.random() * Math.random() );
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes( udid );
				EncryptedLocalStore.setItem( 'udid', bytes );
				return MD5.encrypt( udid );
			}
		}

		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			cocoafish.sendRequest( _route, _method, _param, _requestComplete, false );
		}
		
		private function _requestComplete( data:Object ):void {
			if( data is IOErrorEvent ){
				super.throwError( this, new IOError(data.text) );
				return;
			}
			super.latestData = data;
			_destroyTimer();// を破棄する
			super.executeComplete();// 処理を終了する
		}

		
		/**
		 * 中断実行されるコマンドの実装です。
		 */
		private function _interruptFunction():void {
			// Timer を破棄する
			_destroyTimer();
		}
		
		/**
		 * 破棄します。
		 */
		private function _destroyTimer():void {
		}
		
		/**
		 * <span lang="ja">保持しているデータを解放します。</span>
		 * <span lang="en"></span>
		 */
		override public function dispose():void {
			super.dispose();
		}
		

		override public function toString():String {
			return ObjectUtil.formatToString( this, super.className, super.id ? "id" : null );
		}
		
		
	}
}
