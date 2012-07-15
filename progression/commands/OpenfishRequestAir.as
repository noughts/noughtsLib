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
	import flash.data.*;
	import jp.noughts.utils.*;

	public class OpenfishRequestAir extends OpenfishRequestBase {
		
		static public var baseUrl:String = "localhost:8080";

				
		public function OpenfishRequestAir( route:String, method:String=URLRequestMethod.GET, param:Object=null ) {
			if( !cocoafish ){
				cocoafish = new Cocoafish( "appkey", "", baseUrl );
			}

			var udid:String = getUDID();

			_route = route;
			if( param ){
				_param = param;
				if( method == URLRequestMethod.POST ){
					_param.udid = udid;
				}
			} else {
				if( method == URLRequestMethod.POST ){
					_param = {udid: udid}
				}
			}
			
			_method = method;
			
			// 親クラスを初期化する
			super( route, method, param );
		}
		

		// UDIDを取得
		// あればそのまま取得
		// なければ作成して、アプリ削除しても残るデータ領域に保存
		public function getUDID():String{
			var storedValue:ByteArray = EncryptedLocalStore.getItem('udid');
			if( storedValue ){
				return MD5.encrypt( storedValue.readUTFBytes(storedValue.length) );
			} else {
				// 作成して保存
				var now:Date = new Date();
				var udid:String = String( now.getTime() ) + String( Math.random() * Math.random() );
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes( udid );
				EncryptedLocalStore.setItem( 'udid', bytes );
				return MD5.encrypt( udid );
			}
		}

		
		
	}
}
