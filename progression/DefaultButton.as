package jp.noughts.progression{
	import jp.progression.casts.*;
	import jp.progression.commands.display.*;
	import jp.progression.commands.lists.*;
	import jp.progression.commands.managers.*;
	import jp.progression.commands.media.*;
	import jp.progression.commands.net.*;
	import jp.progression.commands.tweens.*;
	import jp.progression.commands.*;
	import jp.progression.data.*;
	import jp.progression.events.*;
	import jp.progression.scenes.*;

	import flash.display.*;
	import flash.geom.*;
	import flash.events.*;

	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;

	import caurina.transitions.Tweener;
	import caurina.transitions.properties.*;


	public class DefaultButton extends CastButton {

		public var view;
		private var _signals:InteractiveObjectSignalSet;
		public function get signals():InteractiveObjectSignalSet{
			return _signals ||= new InteractiveObjectSignalSet(this);
		}


		static public function convert( mc:DisplayObject ):DefaultButton{
			// オリジナルの情報を保持
			var parent_mc = mc.parent;
			var orig_x:Number = mc.x;
			var orig_y:Number = mc.y;
			var depth:uint = parent_mc.getChildIndex( mc );

			var db = new DefaultButton( mc );
			mc.x = 0;
			mc.y = 0;
			parent_mc.addChildAt( db, depth );
			db.x = orig_x;
			db.y = orig_y;
			return db;
		}

		public function DefaultButton( _view:DisplayObject, initObject:Object = null ) {
			// 親クラスを初期化します。
			super( initObject );
			view = _view;
			view.x = 0;
			view.y = 0;
			addChild( view );
			this.mouseChildren = false;
			// 移動先となるシーン識別子を設定します。
			//sceneId = new SceneId( "/index" );

			// 外部リンクの場合には href プロパティに設定します。
			//href = "http://progression.jp/";
			self.addEventListener( MouseEvent.MOUSE_UP, _onMouseUp );
		}

		// atCastMouseUpが反応しない部分があるので追加でlisten
		private function _onMouseUp( e=null ):void{
			var list = new ParallelList();
			list.addCommand(
				new DoTweener( view, {"_brightness":0, time:0} ),
			null);
			list.execute();
		}

		
		// 光って表示させる
		public function flashIn(){
			this.visible = true;
			if( this.alpha == 1 ){
				Tweener.addTween( this, {_brightness:2, time:0} );
				Tweener.addTween( this, {_brightness:0, time:1} );
			} else {
				var targetAlpha:Number = this.alpha;
				this.alpha = 0;
				Tweener.addTween( this, {alpha:targetAlpha, time:1} );
			}
		}


		// ぽこっと表示させる
		public function popIn():void{
			if( this.visible == false ){
				this.visible = true;
				this.scaleX = this.scaleY = 0;
				Tweener.addTween( this, {"_scale":1, time:0.33, transition:"easeOutBack"} )
			}
		}


		/**
		 * IExecutable オブジェクトが AddChild コマンド、または AddChildAt コマンド経由で表示リストに追加された場合に送出されます。
		 * このイベント処理の実行中には、ExecutorObject を使用した非同期処理が行えます。
		 */
		override public function atCastAdded():void {
		}

		/**
		 * IExecutable オブジェクトが RemoveChild コマンド、または RemoveAllChild コマンド経由で表示リストから削除された場合に送出されます。
		 * このイベント処理の実行中には、ExecutorObject を使用した非同期処理が行えます。
		 */
		override public function atCastRemoved():void {
		}

		/**
		 * Flash Player ウィンドウの CastButton インスタンスの上でユーザーがポインティングデバイスのボタンを押すと送出されます。
		 * このイベント処理の実行中には、ExecutorObject を使用した非同期処理が行えます。
		 */
		override public function atCastMouseDown():void {
			var list = new ParallelList();
			list.addCommand(
				new DoTweener( view, {"_brightness":-0.3, time:0} )
			);
			list.execute();
		}

		/**
		 * ユーザーが CastButton インスタンスからポインティングデバイスを離したときに送出されます。
		 * このイベント処理の実行中には、ExecutorObject を使用した非同期処理が行えます。
		 */
		override public function atCastMouseUp():void {
			_onMouseUp();
		}

		/**
		 * ユーザーが CastButton インスタンスにポインティングデバイスを合わせたときに送出されます。
		 * このイベント処理の実行中には、ExecutorObject を使用した非同期処理が行えます。
		 */
		override public function atCastRollOver():void {
		}

		/**
		 * ユーザーが CastButton インスタンスからポインティングデバイスを離したときに送出されます。
		 * このイベント処理の実行中には、ExecutorObject を使用した非同期処理が行えます。
		 */
		override public function atCastRollOut():void {
		}
	}
}

