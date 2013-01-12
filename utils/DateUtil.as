package jp.noughts.utils{

	public class DateUtil {

		static public function format (unixTime_num:uint):String {
			var date:Date = new Date(unixTime_num * 1000);
			var y:uint = date.getFullYear();
			var mo_str:String = add0 (date.getMonth () + 1);
			var d_str:String = add0 (date.getDate ());
			var h_str:String = add0 (date.getHours ());
			var mi_str:String = add0 (date.getMinutes ());

			var s_str:String = add0 (date.getSeconds ());
			var out_str:String = y + "/" + mo_str + "/" + d_str + "  " + h_str + ":" + mi_str;
			return out_str;
		}
		static private function add0 (num:uint):String {
			if (String(num).length == 1) {
				return "0" + String(num);
			} else {
				return String(num);
			}
		}
		//
		//
		//
		static public function getRelativeTime( target_num:uint, now_num:uint=0 ):String {
			if( now_num == 0 ){
				now_num = new Date().getTime() / 1000;
			}

			var gap_num:int = now_num - target_num;
			var out_str:String;
			if( gap_num < 10 ){
				out_str = "数秒前"
			} else if (gap_num < 60) {
				out_str = gap_num + "秒前";
			} else if (gap_num < (60 * 60)) {
				out_str = Math.floor (gap_num / 60) + "分前";
			} else if (gap_num < (60 * 60 * 24)) {
				out_str = Math.floor (gap_num / 60 / 60) + "時間前";
			} else {
				out_str = Math.floor (gap_num / 60 / 60 / 24) + "日前";
			}
			return out_str;
		}

		static public function getGap_en (now_num:Number, target_num:Number):String {
			var gap_num:int = Math.abs (now_num - target_num);
			var out_str:String;
			var num:uint;
			if (gap_num < 60) {
				if (gap_num == 1) {
					out_str = gap_num + " sec ago";
				}else {
					out_str = gap_num + " secs ago";
				}
			} else if (gap_num < (60 * 60)) {
				num = Math.floor (gap_num / 60);
				if (num == 1) {
					out_str = num + " min ago";
				} else {
					out_str = num + " mins ago";
				}
			} else if (gap_num < (60 * 60 * 24)) {
				num = Math.floor (gap_num / 60 / 60);
				if (num == 1) {
					out_str = num + " hour ago";
				} else {
					out_str = num + " hours ago";
				}
			} else {
				num = Math.floor (gap_num / 60 / 60 / 24);
				if (num == 1) {
					out_str = num + " day ago";
				} else {
					out_str = num + " days ago";
				}
			}
			return out_str;
		}

	}
}