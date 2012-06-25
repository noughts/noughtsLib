/*

リモートクライアントで発生する各種イベントです。

*/

package jp.noughts.cirrus{
	import flash.events.*;
	import flash.display.*;
	public class RemoteEvent extends Event{

		public static const LOAD_BOOK_DATA_PROGRESS:String ='loadBookDataProgress';

		private var _data:*;
		public function get data():*{ return _data; }

		public function RemoteEvent( type:String, $data:*=null ){
			super( type );
			_data = $data;
		}
	}
}