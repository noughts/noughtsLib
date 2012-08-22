package jp.noughts.progression.commands{
	import flash.events.Event;		
	import flash.events.IEventDispatcher;
	import jp.progression.commands.*;

	/**
	 * Command Listen を複数のListenに対応したようなもの
	 * @author @quqjp
	 */
	public class MultiListen extends Command {

		//dispatcherリスト
		protected var dispatchers:Vector.<IEventDispatcher> = new Vector.<IEventDispatcher>();
		
		//イベントタイプリスト
		protected var types:Vector.<String> = new Vector.<String>();
			
		//受信したイベントのDispatcher
		protected var _dispatcher:IEventDispatcher;
		public function get dispatcher():IEventDispatcher {
			return _dispatcher;
		}
		
		//受信したイベントのType
		protected var _type:String;
		public function get type():String {
			return _type;
		}
			
		//結果
		protected var _success:Boolean = false;
		public function get success():Boolean{
			return _success;
		}

		public function get eventObject():Event { return _eventObject; }
		private var _eventObject:Event;

		
		public function MultiListen(eventSetList:Array,initObject:Object = null) {	
			// 親クラスを初期化します。
			super( _execute, _interrupt, initObject );
				
			if (eventSetList) {
				var list:Array = eventSetList as Array;
				if (list.length % 2 != 0) {
					throw new Error('引数が対になっていません。');
				}
				var l:uint = list.length;
				var f:Boolean = true;
				for (var i:uint = 0; i < l; i++) {
					if (f) {
						dispatchers.push(IEventDispatcher(list[i]));
					}else {
						types.push(String(list[i]));
					}
					f = !f;
				}
			}
					
		}
		
		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _execute():void {
			var l:uint = dispatchers.length;
			for (var i:uint = 0; i < l; i++) {
				dispatchers[i].addEventListener(types[i],eventHandler);
			}
		}
		//
		private function eventHandler(e:Event):void {
			var l:uint = dispatchers.length;
			for (var i:uint = 0; i < l; i++) {
				if (dispatchers[i] == e.target && types[i] == e.type) {
					this._dispatcher = dispatchers[i];
					this._type = types[i];
					this._success = true;
				}
			}
			if (!this._success) {
				throw new Error('対象のeventDispatcher、typeがみつかりません');
			}
			destroy();

			_eventObject = e;

			executeComplete();
		}
		
		/**
		 * 中断されるコマンドの実装です。
		 */
		private function _interrupt():void {
			destroy();
		}
		
		/**
		 * 破壊
		 */
		protected function destroy():void{
			if(dispatchers){
				var l:uint = dispatchers.length;
				for (var i:uint = 0; i < l; i++) {
					dispatchers[i].removeEventListener(types[i],eventHandler);
				}
			}
		}
			
	}
}