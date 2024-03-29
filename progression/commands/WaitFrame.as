/**

指定したフレーム数だけ待機するコマンドです。



 */
package jp.noughts.progression.commands{
	import jp.progression.commands.*;
	import flash.events.*;
	import flash.display.*;
	import flash.utils.Timer;
	import jp.nium.core.debug.Logger;
	import jp.nium.utils.ObjectUtil;
	import jp.progression.core.L10N.L10NCommandMsg;
	import jp.progression.core.PackageInfo;
	
	/**
	 * <span lang="ja">Wait クラスは、指定された時間だけ処理を停止させるコマンドクラスです。</span>
	 * <span lang="en"></span>
	 * 
	 * @example <listing version="3.0">
	 * // 10 秒遅延する Wait インスタンスを作成する
	 * var com:Wait = new Wait( 10 );
	 * 
	 * // コマンドを実行する
	 * com.execute();
	 * </listing>
	 */
	public class WaitFrame extends Command {
		
		/**
		 * <span lang="ja">処理を停止させたい時間を秒単位で取得または設定します。
		 * コマンド実行中に値を変更しても、処理に対して反映されません。</span>
		 * <span lang="en"></span>
		 */
		public function get time():uint { return _time; }
		public function set time( value:uint ):void {
			if ( value >= 1000 && PackageInfo.hasDebugger ) {
				Logger.warn( Logger.getLog( L10NCommandMsg.getInstance().WARN_001 ).toString( super.className, "time" ) );
			}
			
			_time = value;
		}
		private var _time:uint = 1;
		
		
		private var spr:Sprite = new Sprite();
		private var _counter:uint = 0;
		
		
		/**
		 * <span lang="ja">新しい WaitFrame インスタンスを作成します。</span>
		 * <span lang="en">Creates a new WaitFrame object.</span>
		 * 
		 * @param time
		 * <span lang="ja">処理を停止させたい時間です。</span>
		 * <span lang="en"></span>
		 * @param initObject
		 * <span lang="ja">設定したいプロパティを含んだオブジェクトです。</span>
		 * <span lang="en"></span>
		 */
		public function WaitFrame( time:uint, initObject:Object = null ) {
			// 引数を設定する
			_time = time;
			
			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, initObject );
			
			if ( _time >= 1000 && PackageInfo.hasDebugger ) {
				Logger.warn( Logger.getLog( L10NCommandMsg.getInstance().WARN_001 ).toString( super.className, "time" ) );
			}
		}
		
		
		
		
		
		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			// 遅延時間が設定されていれば
			if ( _time ) {
				_counter = 0;
				spr.addEventListener( Event.ENTER_FRAME, _onEnterFrame );
			} else {
				// 処理を終了する
				super.executeComplete();
			}
		}
		
		private function _onEnterFrame( e:Event ):void{
			_counter++;
			if( _counter == _time ){
				// Timer を破棄する
				_destroyTimer();
				
				// 処理を終了する
				super.executeComplete();
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
		 * Timer を破棄します。
		 */
		private function _destroyTimer():void {
			spr.removeEventListener( Event.ENTER_FRAME, _onEnterFrame );
			//spr = null;
		}
		
		/**
		 * <span lang="ja">保持しているデータを解放します。</span>
		 * <span lang="en"></span>
		 */
		override public function dispose():void {
			// 親のメソッドを実行する
			super.dispose();
			
			_time = 0;
		}
		
		/**
		 * <span lang="ja">Wait インスタンスのコピーを作成して、各プロパティの値を元のプロパティの値と一致するように設定します。</span>
		 * <span lang="en">Duplicates an instance of an Wait subclass.</span>
		 * 
		 * @return
		 * <span lang="ja">元のオブジェクトと同じプロパティ値を含む新しい Wait インスタンスです。</span>
		 * <span lang="en">A new Wait object that is identical to the original.</span>
		 */
		override public function clone():Command {
			return new WaitFrame( _time, this );
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
			return ObjectUtil.formatToString( this, super.className, super.id ? "id" : null, "time" );
		}
		
		
		
	}
}
