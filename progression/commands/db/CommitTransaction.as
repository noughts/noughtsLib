package jp.noughts.progression.commands.db{
	import flash.errors.*;
	import flash.net.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.display.*;
	import jp.progression.commands.*;
	import jp.nium.core.debug.Logger;
	//import jp.nium.utils.ObjectUtil;
	import mx.utils.*;
	import jp.progression.core.PackageInfo;
	import jp.noughts.utils.*;

	import flash.data.*;



	public class CommitTransaction extends Command {
		
		private var _connection:SQLConnection;
		private var _juggler:Sprite = new Sprite();


				
		public function CommitTransaction( connection:SQLConnection ){
			_connection = connection;

			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, null );
		}


		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			Logger.info( "CommitTransaction 開始..." )
			if( _connection.inTransaction ){
				_commitTransaction()
			} else {
				trace( "CommitTransaction 他のトランザクションが終了するのを待ちます" );
				_juggler.addEventListener( Event.ENTER_FRAME, _onEnterFrame );
			}

		}
		


		// ループして他のトランザクションの終了を待つ
		private function _onEnterFrame( e:Event ):void{
			if( _connection.inTransaction ){
				trace( "CommitTransaction 他のトランザクションが終了するのを待っています..." );
			} else {
				_juggler.removeEventListener( Event.ENTER_FRAME, _onEnterFrame );
				_commitTransaction()
			}
		}


		private function _commitTransaction():void{
			Logger.info( "CommitTransaction コミットを開始します..." )
			_juggler.removeEventListener( Event.ENTER_FRAME, _onEnterFrame );
			_connection.addEventListener( SQLEvent.COMMIT, _onCommitComplete );
			_connection.commit();
		}




		private function _onCommitComplete( e:SQLEvent ):void{
			Logger.info( "CommitTransaction コミット完了!" )
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
			_connection.removeEventListener( SQLEvent.COMMIT, _onCommitComplete );
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
