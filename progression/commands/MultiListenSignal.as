/**
 * Progression 4
 * 
 * @author Copyright (C) 2007-2010 taka:nium.jp, All Rights Reserved.
 * @version 4.0.22
 * @see http://progression.jp/
 * 
 * Progression Libraries is dual licensed under the "Progression Library License" and "GPL".
 * http://progression.jp/license
 */
package jp.noughts.progression.commands {
	import jp.progression.commands.*;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import jp.nium.utils.ObjectUtil;
	import org.osflash.signals.*;
	import org.osflash.signals.events.*;

	/**
	 * <span lang="ja">Listen クラスは、指定された EventDispatcher が指定されたイベントを送出するまで待機処理を行うコマンドクラスです。</span>
	 * <span lang="en"></span>
	 * 
	 * @example <listing version="3.0">
	 * // SerialList インスタンスを作成する
	 * var com:SerialList = new SerialList();
	 * 
	 * // コマンドを登録する
	 * com.addCommand(
	 * 	new Trace( "クリックを待ちます" ),
	 * 	new MultiListenSignal( hoge_sig ),
	 * 	new Trace( "クリックされました" )
	 * );
	 * 
	 * // コマンドを実行する
	 * com.execute();
	 * </listing>
	 */
	public class MultiListenSignal extends Command {
		
		public function get signals():Vector.<Signal> { return _signals; }
		private var _signals:Vector.<Signal>;


		private var _dispatchedSignal:Signal;
		public function get dispatchedSignal():Signal{ return _dispatchedSignal }
		private var _dispatchedArgs:Array;
		public function get dispatchedArgs():Array{ return _dispatchedArgs }
		

		/**
		 * <span lang="ja">イベント待ちをしているかどうかを取得します。</span>
		 * <span lang="en"></span>
		 * 
		 * @see #dispatcher
		 * @see #eventType
		 * @see #listen()
		 */
		public function get listening():Boolean { return _listening; }
		private var _listening:Boolean = false;
		
				
		
		/**
		 * <span lang="ja">新しい Listen インスタンスを作成します。</span>
		 * <span lang="en">Creates a new Listen object.</span>
		 * 
		 * @param dispatcher
		 * <span lang="ja">処理の終了イベントを発行する EventDispatcher インスタンスです。</span>
		 * <span lang="en"></span>
		 * @param eventType
		 * <span lang="ja">発行される終了イベントの種類です。</span>
		 * <span lang="en"></span>
		 * @param initObject
		 * <span lang="ja">設定したいプロパティを含んだオブジェクトです。</span>
		 * <span lang="en"></span>
		 */
		public function MultiListenSignal( signals:Vector.<Signal>, initObject:Object = null ) {
			// 引数を設定する
			_signals = signals;
			
			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, initObject );
		}
		
		
		
		
		
		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			// イベントが存在するかどうか確認する
			if( _signals ){
				_listening = true;
			}
			_signals.forEach( function( item:Signal, index:int, vector:Vector.<Signal> ){
				item.addOnce( _listener )
			} );
		}
		
		/**
		 * 中断実行されるコマンドの実装です。
		 */
		private function _interruptFunction():void {
			_resetSignals();
		}
		
		/**
		 * <span lang="ja">保持しているデータを解放します。</span>
		 * <span lang="en"></span>
		 */
		override public function dispose():void {
			// 親のメソッドを実行する
			super.dispose();
			_listening = false;
			_resetSignals();
		}
		
		/**
		 * <span lang="ja">Func インスタンスのコピーを作成して、各プロパティの値を元のプロパティの値と一致するように設定します。</span>
		 * <span lang="en">Duplicates an instance of an Func subclass.</span>
		 * 
		 * @return
		 * <span lang="ja">元のオブジェクトと同じプロパティ値を含む新しい Func インスタンスです。</span>
		 * <span lang="en">A new Func object that is identical to the original.</span>
		 */
		override public function clone():Command {
			return new MultiListenSignal( _signals, this );
		}
		
		/**
		 * <span lang="ja">指定されたオブジェクトのストリング表現を返します。</span>
		 * <span lang="en">Returns the string representation of the specified object.</span>
		 * 
		 * @return
		 * <span lang="ja">オブジェクトのストリング表現です。</span>
		 * <span lang="en">A string representation of the object.</span>
		 */
		override public function toString():String {
			return ObjectUtil.formatToString( this, super.className, super.id ? "id" : null, "dispatcher", "eventType" );
		}
		
		
		private function _resetSignals():void{
			_signals.forEach( function( item:Signal, index:int, vector:Vector.<Signal> ){
				item.remove( _listener );
			} );
		}
		
		
		/**
		 * dispatcher の eventType イベントが発生した瞬間に送出されます。
		 */
		private function _listener( e:GenericEvent, ...rest:Array ):void {
			// 実行中であれば
			if ( super.state > 1 ) {
				_dispatchedSignal = e.signal as Signal
				_dispatchedArgs = rest;
				_resetSignals();
				super.executeComplete();
			}
		}
	}
}
