package jp.noughts.air {
	import org.osflash.signals.natives.sets.*;
	import org.osflash.signals.natives.*;

	import flash.events.*;
	import flash.text.*;

	/**
	 * @author Jon Adams
	 */
	public class StageTextSignalSet extends EventDispatcherSignalSet {

		public function StageTextSignalSet( target:StageText ) {
			super(target);
		}

		public function get change():NativeSignal {
			return getNativeSignal( Event.CHANGE, Event );
		}

		public function get complete():NativeSignal {
			return getNativeSignal( Event.COMPLETE, Event );
		}

		public function get focusIn():NativeSignal {
			return getNativeSignal( FocusEvent.FOCUS_IN, FocusEvent );
		}

		public function get focusOut():NativeSignal {
			return getNativeSignal( FocusEvent.FOCUS_OUT, FocusEvent );
		}

		public function get keyDown():NativeSignal {
			return getNativeSignal( KeyboardEvent.KEY_DOWN, KeyboardEvent );
		}

		public function get keyUp():NativeSignal {
			return getNativeSignal( KeyboardEvent.KEY_UP, KeyboardEvent );
		}

		// StageText オブジェクトがフォーカスを得た結果として、ソフトキーボードがアクティブ化された後で送出されます。
		public function get softKeyboardActivate():NativeSignal {
			return getNativeSignal( SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATE, SoftKeyboardEvent );
		}

		// StageText オブジェクトがフォーカスを得た結果として、ソフトキーボードがアクティブ化される前に送出されます。
		public function get softKeyboardActivating():NativeSignal {
			return getNativeSignal( SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATING, SoftKeyboardEvent );
		}

		// StageText オブジェクトがフォーカスを失った結果として、ソフトキーボードが非アクティブ化された後で送出されます。
		public function get softKeyboardDeactivate():NativeSignal {
			return getNativeSignal( SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, SoftKeyboardEvent );
		}


		
	}
}