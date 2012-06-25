package jp.noughts.utils{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.utils.Timer;
	
	
	/*======================================================================*//**
	* Browser クラスは、SWFファイルを再生しているブラウザの各種情報を取得します。
	*//*=======================================================================*/
	public class Browser {
		
		/*======================================================================*//**
		* ブラウザとの通信が可能かどうかを返します。
		* @return	通信が可能であれば true を返します。
		*//*=======================================================================*/
		static public function get enable():Boolean {
			if ( !ExternalInterface.available ) { return false; }
			
			if ( !online ) {
				return false;
			}
			
			switch( Capabilities.playerType ) {
				case "ActiveX" :
				case "PlugIn" :
					break;
				case "External" :
				case "StandAlone" :
				default :
					return false;
			}
			
			if ( ExternalInterface.call( 'function() { return true; }' ) == null ) {
				return false;
			}
			
			if ( !_instance ) {
				_internallyCalled = true;
				_instance = new Browser();
			}
			
			return true;
		}
		
		
		/*======================================================================*//**
		* コンテンツがオンライン上で実行されているか返します。
		* @return	ブラウザのコード名
		*//*=======================================================================*/
		static public function get online():Boolean {
			switch ( Security.sandboxType ) {
				case Security.REMOTE :
					return true;
				case Security.LOCAL_WITH_FILE :
				case Security.LOCAL_WITH_NETWORK :
				case Security.LOCAL_TRUSTED :
				default :
			}
			return false;
		}
		
		
		// http://rigureto.jp
		static public function get hostInfo():String {
			return protocol + host;
		}
		
		// /api/mobile/regret/show?guid=ON&regret_id=123456#xyz
		static public function get requestUri():String {
			return pathname + search + hash;
		}
		
		// guid=ON&regret_id=123456
		static public function get queryString():String {
			var out:String = search.substring( 1 );
			return out;
		}
		
		
		// URLのパラメータを連想配列で返す
		static public function get query():Object{
			return queryObject;
		}
		static public function get queryObject():Object{
			var searchParts_array:Array = queryString.split( "&" );

			var out_obj:Object = new Object();
			var pare_array:Array;
			for each (var pare_str:String in searchParts_array) {
				pare_array = pare_str.split( "=" );
				out_obj[pare_array[0]] = pare_array[1];
			}
			return out_obj;
		}
		
		
		
		
		
		
		/*======================================================================*//**
		* ブラウザのコード名を返します。
		* @return	ブラウザのコード名
		*//*=======================================================================*/
		static public function get appCodeName():String {
			if ( !enable ) { return null; }
			return ExternalInterface.call( 'function() { return navigator.appCodeName; }' );
		}
		
		/*======================================================================*//**
		* アプリケーション名を返します。
		* @return	アプリケーション名
		*//*=======================================================================*/
		static public function get appName():String {
			if ( !enable ) { return null; }
			return ExternalInterface.call( 'function() { return navigator.appName; }' );
		}
		
		/*======================================================================*//**
		* バージョンと機種名を返します。
		* @return	バージョンと機種名
		*//*=======================================================================*/
		static public function get appVersion():String {
			if ( !enable ) { return null; }
			return ExternalInterface.call( 'function() { return navigator.appVersion; }' );
		}
		
		/*======================================================================*//**
		* Java アプレットが実行可能かどうかを返します。
		* @return	Java アプレットが実行可能であれば true を返します
		*//*=======================================================================*/
		static public function get javaEnabled():Boolean {
			if ( !enable ) { return false; }
			return ( ExternalInterface.call( 'function() { return navigator.javaEnabled(); }' ) == "true" );
		}
		
		/*======================================================================*//**
		* 言語セットを返します。
		* @return	言語セット
		*//*=======================================================================*/
		static public function get language()				:String {
			if ( !enable ) { return null; }
			return ExternalInterface.call( 'function() { return navigator.language; }' );
		}
		
		/*======================================================================*//**
		* プラットフォームを返します。
		* @return	プラットフォーム
		*//*=======================================================================*/
		static public function get platform():String {
			if ( !enable ) { return null; }
			return ExternalInterface.call( 'function() { return navigator.platform; }' );
		}
		
		/*======================================================================*//**
		* データを送信できるかどうかを返します。
		* @return	データが送信できれば true を返します
		*//*=======================================================================*/
		static public function get taintEnable()			:Boolean {
			if ( !enable ) { return false; }
			return ( ExternalInterface.call( 'function() { return navigator.taintEnable(); }' ) == "true" );
		}
		
		/*======================================================================*//**
		* エージェント名を返します。
		* @return	エージェント名
		*//*=======================================================================*/
		static public function get userAgent():String {
			if ( !enable ) { return null; }
			return ExternalInterface.call( 'function() { return navigator.userAgent; }' );
		}
		
		/*======================================================================*//**
		* URI を返します。
		* @return	URI
		*//*=======================================================================*/
		static public function get locationURI():String {
			if ( !enable ) { return null; }
			return ExternalInterface.call( 'function() { return window.location.href; }' );
		}
		static public function set locationURI( uri			:String ):void {
			if ( !enable ) { return; }
			ExternalInterface.call( 'function() { window.location.href = "' +uri + '"; }' );
		}


		/*======================================================================*//**
		* ドメインを含むURLの接頭辞を返します 例：http://www.example.com/
		* ローカルの場合は空の String を返します。
		*//*=======================================================================*/
		static public function get urlHeader():String {
			if ( !enable ) { return ""; }
			if( online ){
				return protocol + "//" + host + "/";
			} else {
				return "";
			}
		}

		/*======================================================================*//**
		* ポート番号を含むドメインを返します 例：example.com:1234
		*//*=======================================================================*/
		static public function get host():String {
			if ( !enable ) { return ""; }
			return ExternalInterface.call( 'function() { return window.location.host; }' );
		}

		/*======================================================================*//**
		* ドメインを返します 例：example.com
		*//*=======================================================================*/
		static public function get hostname():String {
			if ( !enable ) { return ""; }
			return ExternalInterface.call( 'function() { return window.location.hostname; }' );
		}

		/*======================================================================*//**
		* プロトコルを返します 例：http:
		*//*=======================================================================*/
		static public function get protocol():String {
			if ( !enable ) { return ""; }
			return ExternalInterface.call( 'function() { return window.location.protocol; }' );
		}
	
		/*======================================================================*//**
		* pathnameを返します 例：/aaa/bbb/ccc.cgi( パラメータやハッシュは無し )
		*//*=======================================================================*/
		static public function get pathname():String {
			if ( !enable ) { return ""; }
			return ExternalInterface.call( 'function() { return window.location.pathname; }' );
		}
	
		/*======================================================================*//**
		* searchを返します 例：?KEY=CGI
		*//*=======================================================================*/
		static public function get search():String {
			if ( !enable ) { return ""; }
			return ExternalInterface.call( 'function() { return window.location.search; }' );
		}

		/*======================================================================*//**
		* hashを返します 例：#xyz
		*//*=======================================================================*/
		static public function get hash():String {
			if ( !enable ) { return ""; }
			return ExternalInterface.call( 'function() { return window.location.hash; }' );
		}

		/*======================================================================*//**
		* URI のスキームを返します。
		* @return	URI のスキーム
		*//*=======================================================================*/
		static public function get locationScheme()		:String {
			if ( !enable ) { return null; }
			return locationURI.split( "#" )[0];
		}
		
		/*======================================================================*//**
		* URI のフラグメントを返します。
		* @return	URI のフラグメント
		*//*=======================================================================*/
		static public function get locationFragment()		:String {
			if ( !enable ) { return null; }
			if ( locationURI.indexOf( "#" ) == -1 ) { return null; }
			return locationURI.split( "#" )[1];
		}
		static public function set locationFragment( fragment	:String ):void {
			if ( !enable ) { return; }
			locationURI = locationScheme + "#" + fragment;
		}
		
		/*======================================================================*//**
		* ドキュメントタイトルを指定します。
		* @param	title	新しいドキュメントタイトル
		* @return			ドキュメントタイトル
		*//*=======================================================================*/
		static public function get documentTitle()			:String {
			if ( !enable ) { return null; }
			return ExternalInterface.call( 'function() { return document.title; }' );
		}
		static public function set documentTitle( title		:String ):void {
			if ( !enable ) { return; }
			ExternalInterface.call( 'function() { document.title = "' + title + '"; }' );
		}
		
		/*======================================================================*//**
		* ウィンドウステータスを指定します。
		* @param	title	新しいウィンドウステータス
		* @return			ウィンドウステータス
		*//*=======================================================================*/
		static public function get windowStatus():String {
			if ( !enable ) { return null; }
			return ExternalInterface.call( 'function() { return window.status; }' );
		}
		static public function set windowStatus( status:String ):void {
			if ( !enable ) { return; }
			ExternalInterface.call( 'function() { window.status = "' + status + '"; }' );
		}
		
		/*======================================================================*//**
		*//*=======================================================================*/
		static private var _instance						:Browser;
		static private var _eventDispatcher					:EventDispatcher;
		static private var _internallyCalled				:Boolean = false;
		
		
		
		
		
		/*======================================================================*//**
		*//*=======================================================================*/
		private var _oldLocationURI							:String;
		private var _oldDocumentTitle						:String;
		private var _timer									:Timer;
		
		
		
		
		
		/*======================================================================*//**
		* @private
		*//*=======================================================================*/
		public function Browser() {
			if ( !_internallyCalled ) {
				// エラーを送出する
				throw new IllegalOperationError( "Browser クラスはインスタンスを生成できません。" );
			}
			
			_internallyCalled = false;
			
			// EventDispatcher を作成する
			_eventDispatcher = new EventDispatcher();
			
			// Timer を作成する
			_timer = new Timer( 500 );
			_timer.addEventListener( TimerEvent.TIMER, _observe );
			_timer.start();
		}
		
		
		
		// ページの先頭へジャンプ
		static public function jumpToTop(){
			if ( !enable ) { return; }
			ExternalInterface.call( 'function() { window.scrollTo(0,0); }' );
		}
		
		/*======================================================================*//**
		* 任意の JavaScript を使用します。
		* @param	funcName	実行したい関数名を指定します。
		* @param	...args		引数に指定したい値を指定します。
		* @return				関数の戻り値を返します。
		*//*=======================================================================*/
		static public function call( funcName:String, ...args:Array ):String {
			if ( !enable ) { return null; }
			args.unshift( funcName );
			return ExternalInterface.call.apply( null, args );
		}
		
		/*======================================================================*//**
		* JavaScript を使用したアラートを表示します。
		* @param	message	出力したいメッセージ
		*//*=======================================================================*/
		static public function alert( message:String ):void {
			if ( !enable ) { return; }
			ExternalInterface.call( 'function() { alert("' + message + '"); }' );
		}
		
		/*======================================================================*//**
		* ブラウザを再読み込みします。
		*//*=======================================================================*/
		static public function reload():void {
			if ( !enable ) { return; }
			ExternalInterface.call( 'function() { location.reload(); }' );
		}
		
		/*======================================================================*//**
		* ブラウザの印刷ダイアログを表示します。
		*//*=======================================================================*/
		static public function print():void {
			if ( !enable ) { return; }
			ExternalInterface.call( 'function() { window.print(); }' );
		}
		
		/*======================================================================*//**
		* ブラウザの1つ先のページに進みます。
		*//*=======================================================================*/
		static public function historyForward():void {
			if ( !enable ) { return; }
			ExternalInterface.call( 'function() { history.forward(); }' );
		}
		
		/*======================================================================*//**
		* ブラウザの1つ前のページに戻ります。
		*//*=======================================================================*/
		static public function historyBack():void {
			if ( !enable ) { return; }
			ExternalInterface.call( 'function() { history.back(); }' );
		}
		
		/*======================================================================*//**
		*//*=======================================================================*/
		static public function addEventListener( type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false ):void {
			if ( !enable ) { return; }
			_eventDispatcher.addEventListener( type, listener, useCapture, priority );
		}
		
		/*======================================================================*//**
		*//*=======================================================================*/
		static public function hasEventListener( type:String ):Boolean {
			if ( !enable ) { return false; }
			return _eventDispatcher.hasEventListener( type );
		}
		
		/*======================================================================*//**
		*//*=======================================================================*/
		static public function removeEventListener( type:String, listener:Function, useCapture:Boolean = false ):void {
			if ( !enable ) { return; }
			_eventDispatcher.removeEventListener( type, listener, useCapture );
		}
		
		/*======================================================================*//**
		*//*=======================================================================*/
		static public function willTrigger( type:String ):Boolean {
			if ( !enable ) { return false; }
			return _eventDispatcher.willTrigger( type );
		}
		
		
		
		
		
		/*======================================================================*//**
		*//*=======================================================================*/
		private function _observe( e:TimerEvent ):void {

		}
	}
}





