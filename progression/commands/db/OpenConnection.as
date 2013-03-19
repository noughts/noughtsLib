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



	public class OpenConnection extends Command {
		
		private var _connection:SQLConnection;
		private var _reference:Object;

				
		public function OpenConnection( connection:SQLConnection, reference:Object=null, openMode:String = "create", responder:Responder = null, autoCompact:Boolean = false, pageSize:int = 1024, encryptionKey:ByteArray = null ){
			_connection = connection;
			_reference = reference

			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, null );
		}


		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			Logger.info( "OpenConnection 開始..." )
			_connection.addEventListener( SQLEvent.OPEN, _onOpenConnection );
			_connection.openAsync( _reference );
		}
		

		private function _onOpenConnection( event:SQLEvent ):void{
			Logger.info( "OpenConnection 完了" )
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
			_connection.removeEventListener( SQLEvent.RESULT, _onOpenConnection );
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
