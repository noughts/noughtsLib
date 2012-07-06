/*
1秒間に確実に1000回、タイマーイベントを発行します。

使い方
import jp.noughts.utils.ConstantTimer;
import jp.noughts.utils.ConstantTimerEvent;

var ct = new ConstantTimer();
function ctTimerHandler (e:ConstantTimerEvent) {
trace (e.count_num);
}
ct.addEventListener ("timer", ctTimerHandler);
ct.start();



仕組み
標準のTimerで20msごと(正確ではない)に、getTimerによる正確な経過時間をチェック
flash内部で20ms経過するうちに、正確には何ms経過したかを測定し
その回数分のイベントを発行していく。

例：
flashで20msたつうちに、正確には25ms経っていた。
なので25回イベントを発行。


*/



package jp.noughts.utils{

	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import org.osflash.signals.*;


	public class ConstantTimer extends EventDispatcher {

		public var speed:Number = 1;
		private var currentCount_num:Number;
		private var startTime_num:uint;
		private var prevCount_num:uint;
		private var myTimer:Timer;
		private var pause_bool:Boolean = false;

		public var timer_sig:Signal = new Signal( uint );

		public function ConstantTimer ():void {
			myTimer = new Timer (30, 0);
		}
		public function start ():void {
			startTime_num = getTimer();
			myTimer.addEventListener ("timer", timerHandler);
			currentCount_num = 0;
			prevCount_num = 0;
			myTimer.start ();
		}
		public function pause ():void {
			pause_bool = true;
			myTimer.removeEventListener ("timer", timerHandler);
			myTimer.stop ();
		}
		public function resume ():void {
			if (pause_bool == true) {
				pause_bool = false;
				prevCount_num = getRealCount ();
				myTimer.addEventListener ("timer", timerHandler);
				myTimer.start ();
			}
		}
		public function stop ():void {
			myTimer.removeEventListener ("timer", timerHandler);
			myTimer.stop ();
		}

		private function timerHandler (e:TimerEvent):void {
			var realTime_num:uint = getRealCount ();
			var gap_num:Number = realTime_num - prevCount_num;
			if (gap_num > 0) {
				dispatchEvents (gap_num);
			}
			//
			prevCount_num = realTime_num;
		}

		private function dispatchEvents (gap_num:uint):void {
			for (var i:uint = 0; i < Math.ceil(gap_num * speed); i++) {
				//var cte:ConstantTimerEvent = new ConstantTimerEvent("timer");
				//cte.count_num = currentCount_num;
				//dispatchEvent (cte);
				timer_sig.dispatch( currentCount_num )
				currentCount_num++;
			}
		}

		private function getRealCount ():uint {
			return getTimer() - startTime_num;
		}
	}
}