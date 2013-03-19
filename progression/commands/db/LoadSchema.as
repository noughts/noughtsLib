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



	public class LoadSchema extends Command {
		
		private var _connection:SQLConnection;
		private var _sql:String
		private var _params:Array;
		private var _stmt:SQLStatement;

				
		public function LoadSchema( connection:SQLConnection, type:Class=null, name:String=null, database:String="main", includeColumnSchema:Boolean=true, responder:Responder=null ){
			_connection = connection;

			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, null );
		}


		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			Logger.info( "LoadSchema 開始..." )
			_connection.addEventListener( SQLEvent.SCHEMA, _onSchema );
			_connection.addEventListener( SQLErrorEvent.ERROR, _onError );
			_connection.loadSchema();
		}
		

		private function _onSchema( e:SQLEvent ):void{
			Logger.info( "LoadSchema 終了" )
			_destroy();
			super.executeComplete();// 処理を終了する
		}

		private function _onError( e:SQLErrorEvent ):void{
			Logger.info( "LoadSchema エラー", e )
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
			_connection.removeEventListener( SQLEvent.SCHEMA, _onSchema );
			_connection.removeEventListener( SQLErrorEvent.ERROR, _onError );
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
