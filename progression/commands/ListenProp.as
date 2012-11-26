/*

HOW TO USE

指定したオブジェクトのプロパティに値が入ることを監視します。

var com:SerialList = new SerialList();
com.addCommand(
	someFunc,
	new ListenProp( Index, user ),
	function(){
		trace( Index.user がセットされました。 )
	}
)

*/

package jp.noughts.progression.commands {
	import jp.progression.commands.*;
	import flash.display.*;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import jp.nium.utils.ObjectUtil;
	import org.osflash.signals.*;

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
	 * 	new ListenProp( hoge_sig ),
	 * 	new Trace( "クリックされました" )
	 * );
	 * 
	 * // コマンドを実行する
	 * com.execute();
	 * </listing>
	 */
	public class ListenProp extends Command {
		
		private var _target_obj:Object;
		private var _propName:String;

		static private var looper_mc:Sprite = new Sprite()

		
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
		public function ListenProp( target_obj:Object, propName:String, initObject:Object = null ) {
			// 引数を設定する
			_target_obj = target_obj;
			_propName = propName
			
			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, initObject );
		}
		
		
		
		
		
		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			// イベントが存在するかどうか確認する
			if( _target_obj ){
				_listening = true;
				looper_mc.addEventListener( Event.ENTER_FRAME, _loop );
			}
		}
		
		/**
		 * 中断実行されるコマンドの実装です。
		 */
		private function _interruptFunction():void {
			trace( "_interruptFunction" )
			looper_mc.removeEventListener( Event.ENTER_FRAME, _loop );
		}
		
		/**
		 * <span lang="ja">保持しているデータを解放します。</span>
		 * <span lang="en"></span>
		 */
		override public function dispose():void {
			trace( "dispose" )
			// 親のメソッドを実行する
			super.dispose();
			_listening = false;
			_target_obj = null;
			looper_mc.removeEventListener( Event.ENTER_FRAME, _loop );
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
			return new ListenProp( _target_obj, _propName, this );
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
		



		private function _loop(e:Event):void{
			//trace( e )
			if( _target_obj[_propName] === null ){
			} else {
				looper_mc.removeEventListener( Event.ENTER_FRAME, _loop );
				super.executeComplete();
				_target_obj = null;
			}
		}





















		
		
		
	}
}
