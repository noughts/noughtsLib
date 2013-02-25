package jp.noughts.progression.commands{
	import flash.errors.*;
	import flash.net.*;
	import flash.events.*;
	import flash.utils.*;
	import jp.progression.commands.*;
	import jp.nium.core.debug.Logger;
	//import jp.nium.utils.ObjectUtil;
	import mx.utils.*;
	import jp.progression.core.PackageInfo;
	import jp.noughts.cocoafish.sdk.Cocoafish;
	import jp.noughts.utils.*;
	import jp.dividual.nativeExtensions.utils.*;


	public class OpenfishRequest extends Command {
		
		static protected var cocoafish;
		static public var baseUrl:String = "localhost:8080";
		static public var defaultVerbose:Boolean = false
		protected var _route:String
		protected var _param:Object
		protected var _method:String;
		private var _verbose:Boolean = false;
		private var _requestStartedAt = 0;

				
		public function OpenfishRequest( route:String, method:String, param:Object=null, verbose:Object=null, initObject:Object=null ) {
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

			if( verbose===null ){
				_verbose = defaultVerbose;
			} else {
				_verbose = Boolean(verbose)
			}

			if( initObject===null ){
				initObject = new Object()
			}
			if( !initObject.catchError ){
				initObject.catchError = _onCatchError;
			}
			
			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, initObject );
		}
		
		private function _onCatchError( c:Command, err:Error ):void{
			trace( "OpenfishRequest 通信エラー。処理を中断します", err )
			c.interrupt( true )
			onError()
		}


		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			if(_verbose) {
				var d = new Date();
				_requestStartedAt = d.getTime();
			}

			var isSecure:Boolean = false;
			if( getRunsOnGAEServer() ){
				isSecure = true;
			}
			cocoafish.sendRequest( _route, _method, _param, _requestComplete, isSecure );
			NativeUtils.setNetworkActivityIndicatorVisible( true );
		}
		


		private function _requestComplete( data:Object ):void {
			NativeUtils.setNetworkActivityIndicatorVisible( false );
			if( data is IOErrorEvent ){
				super.throwError( this, new IOError(data.text) );
				//super.throwError( this, new IOError("OpenfishRequest error") );
				return;
			}

			if( _verbose ){
				Logger.info( ObjectUtil.toString(data) );
				var d = new Date();
				Logger.info( "ElapsedTime:", d.getTime() - _requestStartedAt, _route, _method );
			}


			//if( data.meta.status=="fail" ){
			//	super.throwError( this, new IOError("status が fail です") );
			//	return;
			//}

			
			super.latestData = data;
			_destroyTimer();// を破棄する
			super.executeComplete();// 処理を終了する

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
		

		//override public function toString():String {
		//	return ObjectUtil.toString( this );
		//}
		
		
	}
}
