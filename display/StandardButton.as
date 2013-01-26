package jp.noughts.display{
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


	public class StandardButton extends Sprite {

		private var _signals:InteractiveObjectSignalSet;
		public function get signals():InteractiveObjectSignalSet{
			return _signals ||= new InteractiveObjectSignalSet(this);
		}

		private var _view;
		public function get view():MovieClip{ return _view }

		static public function convert( mc:DisplayObject ):StandardButton{
			// オリジナルの情報を保持
			var parent_mc = mc.parent;
			var orig_x:Number = mc.x;
			var orig_y:Number = mc.y;
			var depth:uint = parent_mc.getChildIndex( mc );

			var db = new StandardButton( mc );
			mc.x = 0;
			mc.y = 0;
			parent_mc.addChildAt( db, depth );
			db.x = orig_x;
			db.y = orig_y;
			return db;
		}

		public function StandardButton( $view:DisplayObject ) {
			_view = $view;
			view.x = 0;
			view.y = 0;
			addChild( view );
			this.mouseChildren = false;

			signals.mouseUp.add( _onMouseUp )
			signals.mouseDown.add( _onMouseDown )
			signals.mouseOut.add( _onMouseUp )
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

		// ゆっくり明滅させる
		private var blink_list:LoopList
		public function startBlink(){
			if( blink_list ){
				return;
			}
			blink_list = new LoopList()
			blink_list.addCommand(
				new DoTweener( this, {_brightness:0.5, time:0.5} ),
				new DoTweener( this, {_brightness:0, time:0.5} ),
			null);
			blink_list.execute()
		}
		public function stopBlink(){
			if( !blink_list ){
				return;
			}
			blink_list.stop()
			blink_list = null;
			Tweener.addTween( this, {_brightness:0, time:0} );
		}


		private function _onMouseDown( e ):void {
			var list = new ParallelList();
			list.addCommand(
				new DoTweener( view, {"_brightness":-0.66, time:0} )
			);
			list.execute();
		}


		private function _onMouseUp( e=null ):void{
			var list = new ParallelList();
			list.addCommand(
				new DoTweener( view, {"_brightness":0, time:0} ),
			null);
			list.execute();
		}



	}
}

