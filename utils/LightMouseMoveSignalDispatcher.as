package jp.noughts.utils{
	import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;

	public class LightMouseMoveSignalDispatcher extends EventDispatcher{

		public var mouseMove:Signal = new Signal( int, int )
		private stage:Stage;
		private var enterFrame_nsig:NativeSignal;
		private var _prevFrameMouse_pt:Point = new Point(0,0);// 前のフレームのマウス座標( MOUSE_MOVE シミュレート用 )



    	public function LightMouseMoveSignalDispatcher( $stage:Stage ){
    		stage = $stage;
    		enterFrame_nsig = new NativeSignal( stage, Event.ENTER_FRAME, Event )
    		enterFrame_nsig.add( _onEnterFrame )
		}

		private function _onEnterFrame( e:Event ):void{
			var sx:int = stage.mouseX;
			var sy:int = stage.mouseY;

			if( sx != _prevFrameMouse_pt.x || sy != _prevFrameMouse_pt.y ){
				mouseMove.dispatch( sx, sy );
			}
			_prevFrameMouse_pt.setTo( sx, sy )
		}

		public function dispose():void{
    		enterFrame_nsig.remove( _onEnterFrame )
		}
	}

}