/*

HOW TO USE

private function _autoLogin(){
	var slist:SerialList = new SerialList();
	slist.addCommand(
		OpenfishRequestAir.autoLogin(),
		function(){
			var result = this.latestData;
			Logger.info( ObjectUtil.toString(result) )
			Index.user = result.response.users[0]
		},

	null);
	slist.execute();	
}




*/


package jp.noughts.progression.commands{
	import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import mx.utils.*;

	import jp.noughts.cocoafish.sdk.Cocoafish;
	import flash.data.*;
	import jp.noughts.utils.*;

	public class OpenfishRequestAir extends OpenfishRequestBase {
		
		//static public var baseUrl:String = "localhost:8080";

				
		public function OpenfishRequestAir( route:String, method:String=URLRequestMethod.GET, param:Object=null ) {
			super( route, method, param );
		}


		// ログイン情報が保存されているかチェックします。
		static public function get isRegistered():Boolean{
			var storedUsername:ByteArray = EncryptedLocalStore.getItem('openfishAutoLoginUsername');
			var storedPassword:ByteArray = EncryptedLocalStore.getItem('openfishAutoLoginPassword');
			var facebookAccessToken:ByteArray = EncryptedLocalStore.getItem('openfishFacebookAccessToken');
			if( storedUsername && storedPassword ){
				return true
			} else if( facebookAccessToken ){
				return true
			} else {
				return false;
			}
		}

		// EncryptedLocalStore をリセットします。
		static public function resetELS():void{
			Logger.warn( "*************** OpenfishRequestAir ELSをリセットします ******************" )
			EncryptedLocalStore.reset();
		}
		

		// 自動ユーザー登録コマンドを作成して返す
		static private function autoCreateUser():SerialList{
			var slist:SerialList = new SerialList();
			slist.addCommand(
				function(){
					Logger.info( "自動ユーザー登録します。" )
				},
				new OpenfishRequest( "v1/users/create.json", "GET" ),
				function(){
					Logger.info( "自動ユーザー登録完了" )
					var result = this.latestData;
					//Logger.info( ObjectUtil.toString(result) );
					var username:ByteArray = new ByteArray();
					username.writeUTFBytes( result.response.users[0].username );
					var password:ByteArray = new ByteArray();
					password.writeUTFBytes( result.response.users[0].password );
					EncryptedLocalStore.setItem( 'openfishAutoLoginUsername', username );
					EncryptedLocalStore.setItem( 'openfishAutoLoginPassword', password );
					slist.parent.latestData = this.latestData;
				},
			null);
			return slist;
		}


		// 自動ログインコマンドを作成して返す
		static public function autoLogin():SerialList{
			var slist:SerialList = new SerialList();
			slist.addCommand(
				function(){
					Logger.info( "自動ログインします。" )
					var facebookAccessToken_ba:ByteArray = EncryptedLocalStore.getItem('openfishFacebookAccessToken');

					if( facebookAccessToken_ba ){
						var accessToken:String = facebookAccessToken_ba.readUTFBytes( facebookAccessToken_ba.length );
						slist.insertCommand( new OpenfishRequest( "v1/users/external_account_login.json", URLRequestMethod.POST, {
							type: "facebook",
							token: accessToken
						} ));
					} else {
						var storedUsername:ByteArray = EncryptedLocalStore.getItem('openfishAutoLoginUsername');
						var storedPassword:ByteArray = EncryptedLocalStore.getItem('openfishAutoLoginPassword');
						var username_str:String = storedUsername ? storedUsername.readUTFBytes( storedUsername.length ) : "";
						var password_str:String = storedPassword ? storedPassword.readUTFBytes( storedPassword.length ) : "";
						slist.insertCommand( new OpenfishRequest( "v1/users/login.json", URLRequestMethod.POST, {
							login: username_str,
							password: password_str
						}, null, {catchError:onAutoLoginError} ));
					}
				},
				function(){
					Logger.info( "自動ログイン完了!" )
					slist.latestData = this.latestData;
				},
			null);
			return slist;
		}

		static private function onAutoLoginError( com:Command, err:Error ):void{
			Logger.info( "自動ログインに失敗したので自動ユーザー作成します。" )
			com.parent.insertCommand( autoCreateUser() )
			com.executeComplete()
		}


		static public function facebookLogin( accessToken:String ):SerialList{
			var slist:SerialList = new SerialList();
			slist.addCommand(
				new OpenfishRequest( "v1/users/external_account_login.json", URLRequestMethod.POST, {
					type: "facebook",
					token: accessToken
				} ),
				function(){
					Logger.info( "facebookログイン完了" )
					var accessToken_ba:ByteArray = new ByteArray();
					accessToken_ba.writeUTFBytes( accessToken );
					EncryptedLocalStore.setItem( 'openfishFacebookAccessToken', accessToken_ba );
					slist.parent.latestData = this.latestData;
				},
			null);
			return slist;
		}





		// UDIDを取得
		// あればそのまま取得
		// なければ作成して、アプリ削除しても残るデータ領域に保存
		public function getUDID():String{
			var storedValue:ByteArray = EncryptedLocalStore.getItem('udid_ver20120725');
			if( storedValue ){
				return storedValue.readUTFBytes( storedValue.length );
			} else {
				// 作成して保存
				var udid:String = UIDUtil.createUID();
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes( udid );
				EncryptedLocalStore.setItem( 'udid_ver20120725', bytes );
				return udid;
			}
		}

		
		
	}
}
