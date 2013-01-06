package jp.noughts.utils{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.geom.*;

	public class StringUtil{



		// メールアドレスバリデーション
		public static function validateMailAddress( mailaddress_str:String ):Boolean{
			var myRegEx:RegExp = /^[a-z][\w.-]+@\w[\w.-]+\.[\w.-]*[a-z][a-z]$/i; 
			if( mailaddress_str.match(myRegEx) == null ){
				return false;
			} else {
				return true;
			}
		}



	}

}