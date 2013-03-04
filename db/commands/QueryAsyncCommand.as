package jp.noughts.db.commands{
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



	public class QueryAsyncCommand extends Command {
		
		private var _connection:SQLConnection;
		private var _sql:String
		private var _params:Array;
		private var _stmt:SQLStatement;

				
		public function QueryAsyncCommand( connection:SQLConnection, sql:String, ...params:Array ){
			_connection = connection;
			_sql = sql;
			_params = params;

			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, null );
		}


		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			_stmt = new SQLStatement();

			_stmt.sqlConnection = _connection;
			_stmt.text = _sql;

			var paramsFound:Boolean = false
			if( _params.length == 1 && _params[0]!=null ){
				if( _params[0] is Array ){	
					_params = _params[0];
				}
				paramsFound = true;
			}

			if( paramsFound ){
				for (var i:int = 0; i < _params.length; i++){
					_stmt.parameters[i] = _params[i];
				}
			}
			//trace( "_params", ObjectUtil.toString(_params) )
			//trace( "_stmt", ObjectUtil.toString(_stmt.parameters) )

			_stmt.addEventListener( SQLEvent.RESULT, _onSQLComplete );
			_stmt.execute();
		}
		

		private function _onSQLComplete( e:SQLEvent ):void{
			var result:SQLResult = _stmt.getResult();
			super.latestData = _sql.toUpperCase().indexOf("SELECT ") == 0 ? result.data || [] : result.rowsAffected;
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
			_stmt.removeEventListener( SQLEvent.RESULT, _onSQLComplete );
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
