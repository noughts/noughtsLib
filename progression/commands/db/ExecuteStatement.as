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



	public class ExecuteStatement extends Command {
		
		private var _stmt:SQLStatement;

				
		public function ExecuteStatement( statement:SQLStatement, prefetch:int=-1, responder:Responder=null ){
			_statement = statement;

			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, null );
		}


		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			_statement.addEventListener( SQLEvent.RESULT, resultHandler );
			_statement.execute();
		}
		

		private function resultHandler( event:SQLEvent ):void{
		    var result:SQLResult = _statement.getResult();
		    if( result != null ){
		    	super.data = result;
		    }
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
			_statement.removeEventListener( SQLEvent.RESULT, resultHandler );
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
