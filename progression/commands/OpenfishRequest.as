package jp.noughts.progression.commands{
	import flash.errors.*;
	import flash.net.*;
	import flash.events.*;
	import flash.utils.*;
	import jp.progression.commands.*;
	import jp.nium.core.debug.Logger;
	import jp.nium.utils.ObjectUtil;
	import jp.progression.core.PackageInfo;
	import com.cocoafish.sdk.Cocoafish;
	import jp.noughts.utils.*;

	public class OpenfishRequest extends OpenfishRequestBase {
		
		static public var baseUrl:String = "localhost:8080";

				
		public function OpenfishRequest( route:String, method:String, param:Object=null, initObject:Object = null ) {
			if( !cocoafish ){
				cocoafish = new Cocoafish( "dd", "", baseUrl );
			}


			_route = route;
			
			_method = method;
			
			// 親クラスを初期化する
			super( route, method, param );
		}
		
		
		
	}
}
