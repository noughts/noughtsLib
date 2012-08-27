package jp.noughts.progression.commands{

	import jp.progression.commands.Wait;

	public class MyWait extends Wait{

		static private var _timeScale:Number = 1;

		public function MyWait( time:Number = 1.0, initObject:Object = null ){
			var _t:Number = time / _timeScale;
			super( _t, initObject );
		}

		static public function setTimeScale( val:Number ):void{
			_timeScale = val;
		}

	}


}