package jp.noughts.cirrus{
	import flash.events.Event;

	public class CirrusEvent extends Event {
		public static const LOGIN_COMPLETE:String ='loginComplete';
		public static const INCOMING_CALL:String ='incomingCall';
		public static const CALLING_STARTED:String ='callingStarted';// 呼び出し開始
		public static const CALL_FAILED:String ='callFailed';
		public static const CALL_ACCEPTED:String ='callAccepted';
		public static const CALL_TERMINATED:String ='callTerminated';// 呼び出しが切断された？
		public static const TALK_TERMINATED:String ='taikTerminated';// 会話が切断された
		public static const TALK_STARTED:String ='talkStarted';// 通話開始
		public static const CONNECT_FAILED:String ='connectFailed';// サーバーに接続失敗
		public static const HANGUP:String ='hangup';// 会話が無事終了した

		public function CirrusEvent( type:String ){
			super(type);
		}
	}
}