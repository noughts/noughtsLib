package jp.noughts.progression.commands{
	import flash.errors.*;
	import flash.net.*;
	import flash.events.*;
	import flash.utils.*;
	import jp.progression.commands.*;
	import jp.nium.core.debug.Logger;
	import jp.nium.utils.ObjectUtil;
	import jp.progression.core.PackageInfo;
	import jp.noughts.cocoafish.sdk.Cocoafish;
	import jp.noughts.utils.*;

	public class OpenfishRequestBase extends Command {
		
		static protected var cocoafish;
		static public var baseUrl:String = "localhost:8080";
		static public var verbose:Boolean = false
		protected var _route:String
		protected var _param:Object
		protected var _method:String;

				
		public function OpenfishRequestBase( route:String, method:String, param:Object=null ) {
			if( !cocoafish ){
				cocoafish = new Cocoafish( "dd", "", baseUrl );
			}

			//if( param && param is ByteArray==false && param["photo"] ){
			//	Logger.info( "photoパラメータがあったのでエンコードします。" )
			//	param["photo"] = Base64.encode( param["photo"] )
			//}

			_route = route;
			_param = param;
			_method = method;
			
			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, null );
		}
		

		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			var isSecure:Boolean = false;
			if( getRunsOnGAEServer() ){
				isSecure = true;
			}
			cocoafish.sendRequest( _route, _method, _param, _requestComplete, isSecure );
		}
		
		private function _requestComplete( data:Object ):void {
			if( data is IOErrorEvent ){
				super.throwError( this, new IOError(data.text) );
				return;
			}
			super.latestData = data;
			_destroyTimer();// を破棄する
			super.executeComplete();// 処理を終了する

			if( verbose ){
				Logger.info( ObjectUtil.toString(data) )
			}
		}


		// gaeサーバー上で動いているかどうかを判定
		private function getRunsOnGAEServer():Boolean{
			if( baseUrl.indexOf(".com")>-1 || baseUrl.indexOf(".jp")>-1 ){
				return true;
			} else {
				return false;
			}
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
