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



	public class BeginTransaction extends Command {
		
		// トランザクションをネストしないように、開始したかどうかのステータスを BeginTransaction で共有
		// connection.begin() しても、はじめの statement が開始されるまで inTransaction は false なので、
		// その間あたらしいトランザクションを開始してしまわないようにするための変数
		static private var transactionBegan:Boolean = false;

		private var _connection:SQLConnection;
		private var _option:String
		private var _responder:Responder;

		private var _juggler:Sprite;

				
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
			Logger.info( "BeginTransaction _executeFunction" )
			if( _connection.inTransaction || transactionBegan ){
				trace( "BeginTransaction 他のトランザクションが終了するのを待ちます" );
				_juggler = new Sprite();
				_juggler.addEventListener( Event.ENTER_FRAME, _onEnterFrame );
			} else {
				_beginTransaction()
			}
		}

		

		// ループして他のトランザクションの終了を待つ
		private function _onEnterFrame( e:Event ):void{
			if( _connection.inTransaction ){
				trace( "BeginTransaction 他のトランザクションが終了するのを待っています..." );
			} else {
				_juggler.removeEventListener( Event.ENTER_FRAME, _onEnterFrame );
				_beginTransaction()
			}
		}


		private function _beginTransaction():void{
			Logger.info( "BeginTransaction トランザクションを開始します..." )
			_connection.addEventListener( SQLEvent.BEGIN, _onTransactionBegin );
			_connection.begin( _option  );
			transactionBegan = true;
		}

		
		private function _onTransactionBegin( e:SQLEvent ):void{
			Logger.info( "BeginTransaction トランザクションが開始されました" )
			_destroy();
			transactionBegan = false;
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
