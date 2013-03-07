package jp.noughts.progression.commands.db{
	import flash.errors.*;
	import flash.net.*;
	import flash.events.*;
	import flash.utils.*;
	import jp.progression.commands.*;
	import jp.nium.core.debug.Logger;
	//import jp.nium.utils.ObjectUtil;
	import mx.utils.*;
	import jp.progression.core.PackageInfo;
	import jp.noughts.utils.*;

	import flash.data.*;



	public class BeginTransaction extends Command {
		
		private var _connection:SQLConnection;
		private var _option:String
		private var _responder:Responder;

				
		public function BeginTransaction( connection:SQLConnection, option:String = null, responder:Responder = null ){
			_connection = connection;
			_option = option;
			_responder = responder;

			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, null );
		}


		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			Logger.info( "BeginTransaction 開始..." )
			_connection.addEventListener( SQLEvent.BEGIN, _onTransactionBegin );
			_connection.begin( _option  );
		}
		

		private function _onTransactionBegin( e:SQLEvent ):void{
			Logger.info( "BeginTransaction 終了" )
			_destroy();
			super.executeComplete();// 処理を終了する
		}


		
		/**
		 * 中断実行されるコマンドの実装です。
		 */
		private function _interruptFunction():void {
			// Timer を破棄する
			_destroy();
		}
		
		/**
		 * 破棄します。
		 */
		private function _destroy():void {
			_connection.removeEventListener( SQLEvent.BEGIN, _onTransactionBegin );
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
