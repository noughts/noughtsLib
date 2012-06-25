package jp.noughts.cirrus{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.media.*;
	import flash.utils.*;
	import flash.system.*;
	import mx.collections.ArrayList;
	import mx.formatters.DateFormatter;
	import jp.nium.utils.*;
	import jp.nium.core.debug.Logger;
	import org.osflash.signals.*;

	public class CirrusService extends EventDispatcher{

		// signals
		public var loginComplete_sig:Signal = new Signal();
		public var incomingCall_sig:Signal = new Signal();
		public var callAccepted_sig:Signal = new Signal();// 通話が承諾されました。
		

		public var userName_str:String = "";
		private var _sendVideo_bool:Boolean = true;
		private var _sendAudio_bool:Boolean = true;
		public var watchList_array:Array = new Array();// 位置やサイズを監視するDisplayObject配列

		// リモートマウスイベントに含まない DisplayObject の配列
		public var omitObjectsFromRemoteMouseEvent_array:Array = new Array();

		// rtmfp server address (Adobe Cirrus or FMS)
		public var rtmfpServerUrl_str:String = "rtmfp://p2p.rtmfp.net";

		// developer key, please insert your developer key here
		public var developerKey_str:String = "d8469d9418b91d801e4ed33f-b649dca1f086";

		// please insert your web service URL here for exchanging peer ID
		public var webServiceUrl_str:String = "";

		// cirrus にログインして受け取った ID
		public var identity:String;

		// this is the connection to rtmfp server
		private var netConnection:NetConnection;

		// outgoing media stream (audio, video, text and some control messages)
		public var outgoingStream:NetStream;

		// incoming media stream (audio, video, text and some control messages)
		public var incomingStream:NetStream;

		// ID management serice
		private var idManager:AbstractIdManager;

		public var remoteVideo:Video;
		public var localCamera:Camera;

		private var mic:Microphone;
		private var _currentState:String;
		public function get currentState():String{ return _currentState; }

		// login/registration states
		private const LoginNotConnected:String = "LoginNotConnected";
		private const LoginConnecting:String = "LoginConnecting";
		private const LoginConnected:String = "LoginConnected";
		private const LoginDisconnecting:String = "LoginDisconnecting";

		// call states, only used when LoginConnected
		private const CallReady:String = "CallReady";
		private const CallCalling:String = "CallCalling";
		private const CallRinging:String = "CallRinging";
		static public const CALL_ESTABLISHED:String = "callEstablished";// 通話中
		private const CallFailed:String = "CallFailed";

		// available microphone devices
		private var micNames:ArrayList = new ArrayList();
		private var micIndex:int = 0;

		// available camera deviced
		private var cameraNames:ArrayList = new ArrayList();
		private var cameraIndex:int = 0;

		private var activityTimer:Timer;

		private var remoteName:String = "";
		private var remoteId:String = "";

		private var callTimer:int;

		// charts
		private var audioRate:Array = new Array(30);
		private var audioRateDisplay:ArrayList = new ArrayList();
		private var videoRate:Array = new Array(30);
		private var videoRateDisplay:ArrayList = new ArrayList();
		private var srtt:Array = new Array(30);
		private var srttDisplay:ArrayList = new ArrayList();

		private var ringer:Sound;
		private var ringerChannel:SoundChannel;

		// signaling
		/**
		 * Simple request-reply protocol.
		 *
		 * Call flow 1, caller cancels call
		 * FP1 --- Invite --> FP2
		 * FP1 --- Cancel --> FP2
		 * FP1 <-- Ok ------- FP2
		 *
		 * Call flow 2, callee rejects call
		 * FP1 --- Invite --> FP2
		 * FP1 <-- Reject --- FP2
		 *
		 * * Call flow 3, call established and caller ends call
		 * FP1 --- Invite --> FP2
		 * FP1 <-- Accept --- FP2
		 * FP1 --- Bye -----> FP2
		 * FP1 <-- Ok ------- FP2
		 */
		private const Relay:String = "relay";
		private const Invite:String = "invite";
		private const Cancel:String = "cancel";
		private const Accept:String = "accept";
		private const Reject:String = "reject";
		private const Bye:String = "bye";
		private const Ok:String = "ok";

		// called when application is loaded
		public function CirrusService( $webServiceUrl_str:String ):void{
			status("Player: " + Capabilities.version + "\n");
			webServiceUrl_str = $webServiceUrl_str;
			_currentState = LoginNotConnected;

			var mics:Array = Microphone.names;
			var cameras:Array = Camera.names;

			// マイク取得 enhancedMic が使えれば使う
			mic = Microphone.getEnhancedMicrophone();
			if( mic ){
				Logger.info( "EnhancedMicrophone を使います。" );
				mic = Microphone.getEnhancedMicrophone();
				var options:MicrophoneEnhancedOptions = new MicrophoneEnhancedOptions();
				options.mode = MicrophoneEnhancedMode.FULL_DUPLEX;
				//options.autoGain = true;
				mic.enhancedOptions = options;// Microphone インスタンスにオプションを設定
			} else {
				Logger.info( "通常のマイクを使います。" );
				mic = Microphone.getMicrophone();
				mic.setUseEchoSuppression( true );
			}
			mic.gain = 100;
			mic.setSilenceLevel( 0 );
			mic.codec = SoundCodec.SPEEX;
			mic.enableVAD = false;
			mic.framesPerPacket = 1;
			mic.encodeQuality = 10;
			//mic.setLoopBack( true );

			if (mic){
				mic.addEventListener(StatusEvent.STATUS, onDeviceStatus);
				mic.addEventListener(ActivityEvent.ACTIVITY, onDeviceActivity);
				handleCodecChange();
			}

			// statistics timer
//			activityTimer = new Timer(100);
//			activityTimer.addEventListener(TimerEvent.TIMER, onActivityTimer);
//			activityTimer.start();


			// カメラ取得
			Logger.info( cameras );
			localCamera = Camera.getCamera();
			//localCamera = Camera.getCamera( String(cameras.length-1) );

			//var cameraPositionClass = getDefinitionByName2( "CameraPosition" );
			//if( cameraPositionClass ){
			//	localCamera = getCameraOf( cameraPositionClass.FRONT );// AIR プレーヤー ( for iPad )
			//} else {
			//	localCamera = Camera.getCamera();// ブラウザだと余分なカメラが入っていることがあるので、最初のカメラを取得
			//}

			if (localCamera){
				localCamera.setMode( 640, 480, 30 );
				localCamera.setQuality( 16384/8, 0 );
				localCamera.addEventListener(StatusEvent.STATUS, onDeviceStatus);
				localCamera.addEventListener(ActivityEvent.ACTIVITY, onDeviceActivity);

				//changeCamera( 1 );
			}

			var timer:Timer = new Timer( 30 );
			timer.addEventListener( TimerEvent.TIMER, _watchTimer );
			timer.start();
		}


		private function _watchTimer( e:TimerEvent ):void{
			if( watchList_array.length > 0 ){
				var ary:Array = new Array();
				for( var i:uint=0; i<watchList_array.length;i++ ){
					var mc:DisplayObject = watchList_array[i];
					ary.push( {
						x: mc.x,
						y: mc.y,
						scaleX: mc.scaleX,
						scaleY: mc.scaleY
					} );
				}
				var data:Object = {
					"ary": ary
				};
				var event:RemoteEvent = new RemoteEvent( "watch", data );
				dispatchRemoteEvent( event );
			}
		}


		private function getDefinitionByName2( name:String ):*{
			try{
				var obj = getDefinitionByName(name);
				return obj;
			} catch (e:ReferenceError){
				// Object does not exist
				return false;
			}
		}


		public function dispatchRemoteEvent( e:RemoteEvent ):void{
			if( outgoingStream ){
				var obj:Object = new Object();
				obj.type = e.type;
				obj.data = e.data;
				outgoingStream.send( "handleRemoteEvent", obj );
			}
		}

		// マウスイベントを相手に送る
		public function sendMouseEvent( e:MouseEvent ):void{
			var obj:Object = new Object();
			obj.stageX = e.stageX;
			obj.stageY = e.stageY;
			obj.type = e.type;

			if( outgoingStream ){
				//trace( "send  "+ obj.type );
				outgoingStream.send( "handleRemoteMouseEvent", obj );
			}
		}







		// CameraPosition.FRONT か CameraPosition.BACK を渡す
		private function getCameraOf( position:String ):Camera{
			Logger.info( "getCameraOf "+ position );
			var camera:Camera;
			var cameraCount:uint = Camera.names.length;
			for ( var i:uint = 0; i < cameraCount; ++i ){
				camera = Camera.getCamera( String(i) );
				Logger.info( camera.position );
				if ( camera.position == position ){
					return camera;
				}
			}
			return Camera.getCamera();
		}


		private function status(msg:String):void{
			Logger.info( "CirrusService: " + msg );
		}

		// サーバーにログイン
		public function login( $userName_str:String ):void{
			if( !$userName_str ){
				trace( "ユーザー名が必要です" );
				return;
			}
			userName_str = $userName_str;
			netConnection = new NetConnection();
			trace( ">>>>register" );
			netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);

			// incoming call coming on NetConnection object
			var c:Object = new Object();
			c.onRelay = function(id:String, action:String, name:String):void{
				status("Request: " + action + " from: " + id + " (" + name + ")\n");

				if( action == Invite ){
					// 電話かかってきた
					if( _currentState == CallReady ){
						status( name +"から着信です。" );
						//ring();
						_currentState = CallRinging;

						// callee subscribes to media, to be able to get the remote user name
						incomingStream = new NetStream(netConnection, id);
						incomingStream.addEventListener(NetStatusEvent.NET_STATUS, incomingStreamHandler);
						incomingStream.play("media-caller");

						incomingStream.receiveAudio(false);
						incomingStream.receiveVideo(false);

						incomingStream.client = new CirrusClient();

						remoteName = name;
						remoteId = id;

						incomingCall_sig.dispatch();
						dispatchEvent( new CirrusEvent(CirrusEvent.INCOMING_CALL) );
					} else {
						status("Call rejected due to state: " + _currentState + "\n");
						netConnection.call( Relay, null, id, Reject, userName_str );
					}
				} else if( Reject == action ){
					_currentState = CallReady;
					hangup();
				} else if (Accept == action){
					if (_currentState != CallCalling){
						status("Call accept: Wrong call state: " + _currentState + "\n");
						return;
					}
					status( "通話を承諾されました。" );
					_currentState = CALL_ESTABLISHED;
					callAccepted_sig.dispatch();
					dispatchEvent( new CirrusEvent(CirrusEvent.CALL_ACCEPTED) );
					dispatchEvent( new CirrusEvent(CirrusEvent.TALK_STARTED) );
				} else if( Bye == action ){
					netConnection.call( Relay, null, id, Ok, userName_str );
					_currentState = CallReady;
					hangup();
				} else if( Cancel == action ){
					netConnection.call( Relay, null, id, Ok, userName_str );
					_currentState = CallReady;
					hangup();
				}
			}
			netConnection.client = c;
			try {
				netConnection.connect( rtmfpServerUrl_str, developerKey_str );
			} catch (e:ArgumentError){
				status("Incorrect connet URL\n");
				return;
			}
			_currentState = LoginConnecting;
			status("Connecting to " + rtmfpServerUrl_str + "\n");
		}


		private function netConnectionHandler( event:NetStatusEvent ):void{
			status("NetConnection event: " + event.info.code + "\n");
			switch (event.info.code){
				case "NetConnection.Connect.Success":
					connectSuccess();
					break;
				case "NetStream.Connect.Closed":
					if( _currentState != CallReady ){
						_currentState = CallReady;
						status( "通話が切断されました" );
						dispatchEvent( new CirrusEvent(CirrusEvent.TALK_TERMINATED) );
					}
					break;
				case "NetConnection.Connect.Closed":
					break;
				case "NetStream.Connect.Success":
					// we get this when other party connects to our outgoing stream
					status("Connection from: " + event.info.stream.farID + "\n");
					break;
				case "NetConnection.Connect.Failed":
					status("Unable to connect to " + rtmfpServerUrl_str + "\n");
					_currentState = LoginNotConnected;
					dispatchEvent( new CirrusEvent(CirrusEvent.CONNECT_FAILED) );
					break;
			}
		}


		private function outgoingStreamHandler(event:NetStatusEvent):void{
			status("Outgoing stream event: " + event.info.code + "\n");
		}


		private function incomingStreamHandler(event:NetStatusEvent):void{
			status("Incoming stream event: " + event.info.code + "\n");
		}


		// connection to rtmfp server succeeded and we register our peer ID with an id exchange service
		// other clients can use id exchnage service to lookup our peer ID
		private function connectSuccess():void{
			status("Connected, my ID: " + netConnection.nearID + "\n");

            // exchange peer id using web service
			idManager = new HttpIdManager();
			idManager.service = webServiceUrl_str;

          	idManager.addEventListener("registerSuccess", idManagerEvent);
          	idManager.addEventListener("registerFailure", idManagerEvent);
          	idManager.addEventListener("lookupFailure", idManagerEvent);
          	idManager.addEventListener("lookupSuccess", idManagerEvent);
          	idManager.addEventListener("idManagerError", idManagerEvent);

          	idManager.register( userName_str, netConnection.nearID );
          	identity = netConnection.nearID;
		}


		// 実際に電話かける
		public function placeCall( identity:String, user:String=null ):void{
			status("Calling " + user + ", id: " + identity + "\n");

			if (identity.length != 64){
				status("Invalid remote ID, call failed\n");
				_currentState = CallFailed;
				dispatchEvent( new CirrusEvent(CirrusEvent.CALL_FAILED) );
				return;
			}

			netConnection.call( Relay, null, identity, Invite, userName_str );

			// caller publishes media stream
			outgoingStream = new NetStream(netConnection, NetStream.DIRECT_CONNECTIONS);
			outgoingStream.addEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
			outgoingStream.publish("media-caller");

			var o:Object = new Object
			o.onPeerConnect = function(caller:NetStream):Boolean{
				status("Callee connecting to media stream: " + caller.farID + "\n");
				return true;
			}
			outgoingStream.client = o;

			startAudio();
			startVideo();

			// caller subscribes to callee's media stream
			incomingStream = new NetStream(netConnection, identity);
			incomingStream.addEventListener(NetStatusEvent.NET_STATUS, incomingStreamHandler);
			incomingStream.play("media-callee");

			incomingStream.client = new CirrusClient();

			remoteVideo = new Video();
			remoteVideo.width = 320;
			remoteVideo.height = 240;
			remoteVideo.attachNetStream(incomingStream);
//			remoteVideoDisplay.addChild(remoteVideo);

			remoteName = user;
			remoteId = identity;

			_currentState = CallCalling;
			dispatchEvent( new CirrusEvent(CirrusEvent.CALLING_STARTED) );
		}


		// process successful response from id manager
		private function idManagerEvent(e:Event):void{
			status("ID event: " + e.type + "\n");
			if (e.type == "registerSuccess"){
				status( "_currentState="+ _currentState );
				switch (_currentState){
					case LoginConnecting:
						// ログイン完了時
						//_currentState = LoginConnected;
						loginComplete_sig.dispatch();
						dispatchEvent( new CirrusEvent(CirrusEvent.LOGIN_COMPLETE) );
						break;
					case LoginDisconnecting:
					case LoginNotConnected:
						_currentState = LoginNotConnected;
						return;
					case LoginConnected:
						return;
				}
				_currentState = CallReady;

			} else if (e.type == "lookupSuccess"){
				// party query response
				var i:IdManagerEvent = e as IdManagerEvent;
				placeCall( i.user, i.id );
			} else {
				// all error messages ar IdManagerError type
				var error:IdManagerError = e as IdManagerError;
				status("Error description: " + error.description + "\n")
				onDisconnect();
			}
		}

		// 電話に応答
		public function acceptCall():void{
			stopRing();

			incomingStream.receiveAudio( true );
			incomingStream.receiveVideo( true );

			remoteVideo = new Video();
			remoteVideo.width = 320;
			remoteVideo.height = 240;
			remoteVideo.attachNetStream( incomingStream );
//			remoteVideoDisplay.addChild( remoteVideo );

			// 着呼側のメディアをパブリッシュ
			outgoingStream = new NetStream( netConnection, NetStream.DIRECT_CONNECTIONS );
			outgoingStream.addEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
			outgoingStream.publish("media-callee");

			var o:Object = new Object
			o.onPeerConnect = function( caller:NetStream ):Boolean{
				status("Caller connecting to media stream: " + caller.farID + "\n");
				return true;
			}
			outgoingStream.client = o;

			netConnection.call( Relay, null, remoteId, Accept, userName_str );

			startVideo();
			startAudio();

			_currentState = CALL_ESTABLISHED;
			dispatchEvent( new CirrusEvent(CirrusEvent.TALK_STARTED) );
		}


		private function onDisconnect():void{
			status("Disconnecting.\n");
			hangup();
			if (idManager){
				idManager.unregister();
				idManager = null;
			}
			_currentState = LoginNotConnected;
			if( netConnection ){
				netConnection.close();
			}
			netConnection = null;
		}


		// 電話かける試す
		public function callTo( calleeName_str:String ):void{
			if( netConnection && netConnection.connected ){
				if( calleeName_str.length == 0 ){
					status("Please enter name to call\n");
					return;
				}

				// first, we need to lookup callee's peer ID
				if( idManager ){
					idManager.lookup( calleeName_str );
				} else {
					status("Not registered.\n");
					return;
				}
			} else {
				status("Not connected.\n");
			}
		}



		private function startAudio():void{
			status( "startAudio" );
			if( sendAudio_bool ){
				if( mic && outgoingStream ){
					outgoingStream.attachAudio( mic );
				}
			} else {
				if( outgoingStream ){
					outgoingStream.attachAudio( null );
				}
			}
		}


		private function startVideo():void{
			status( "startVideo" );
			if( sendVideo_bool ){
				if( localCamera ){
					if( outgoingStream ){
//						var h264Settings:H264VideoStreamSettings = new H264VideoStreamSettings();
//						h264Settings.setProfileLevel( H264Profile.MAIN, H264Level.LEVEL_3 );
//						outgoingStream.videoStreamSettings = h264Settings;
						outgoingStream.attachCamera( localCamera );
					}
				}
			} else {
				if( outgoingStream ){
					outgoingStream.attachCamera( null );
				}
			}
		}

		// this function is called in every second to update charts, microhone level, and call timer
		private function onActivityTimer(e:TimerEvent):void{
			var mic:Microphone = getMicrophone();
			if (_currentState == CALL_ESTABLISHED && incomingStream && outgoingStream && outgoingStream.peerStreams.length == 1){
				var recvInfo:NetStreamInfo = incomingStream.info;
				var sentInfo:NetStreamInfo = outgoingStream.peerStreams[0].info;

				audioRate.shift();
				var a:Object = new Object;
				a.Recv = recvInfo.audioBytesPerSecond * 8 / 1024;
				a.Sent = sentInfo.audioBytesPerSecond * 8 / 1024;
				audioRate.push(a);

				videoRate.shift();
				var v:Object = new Object;
				v.Recv = recvInfo.videoBytesPerSecond * 8 / 1024;
				v.Sent = sentInfo.videoBytesPerSecond * 8 / 1024;
				videoRate.push(v);

				srtt.shift();
				var s:Object = new Object;
				s.Data = recvInfo.SRTT;
				srtt.push(s);
			}

			if (_currentState == CALL_ESTABLISHED){
				callTimer++;
				var elapsed:Date = new Date(2008, 4, 12);
				elapsed.setTime(elapsed.getTime() + callTimer * 1000);
				var formatter:DateFormatter = new DateFormatter();
				var format:String = "JJ:NN:SS";
				if (callTimer < 60){
					format = "SS";
				} else if (callTimer < 60 * 60){
					format = "NN:SS";
				}
				formatter.formatString = format
			}
		}

		private function onDeviceStatus(e:StatusEvent):void{
			status("Device status: " + e.code + "\n");
		}

		private function onDeviceActivity(e:ActivityEvent):void{
//				status("Device activity: " + e.activating + "\n");
		}


		public function hangup():void{
			status("Hanging up call\n");

			// signaling based on state
			if (CALL_ESTABLISHED == _currentState){
				netConnection.call(Relay, null, remoteId, Bye, userName_str);
			} else if (CallCalling == _currentState){
				netConnection.call(Relay, null, remoteId, Cancel, userName_str);
			} else if (CallRinging == _currentState){
				netConnection.call(Relay, null, remoteId, Reject, userName_str);
			}

			stopRing();
			_currentState = CallReady;

			if (incomingStream){
				incomingStream.close();
				incomingStream.removeEventListener(NetStatusEvent.NET_STATUS, incomingStreamHandler);
			}
			if (outgoingStream){
				outgoingStream.close();
				outgoingStream.removeEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
			}
			incomingStream = null;
			outgoingStream = null;

			remoteName = "";
			remoteId = "";

			callTimer = 0;

			dispatchEvent( new CirrusEvent(CirrusEvent.HANGUP) );
		}


		private function getMicrophone():Microphone{
			return mic;
//			if( enhancedCheckbox.selected ){
//				return Microphone.getEnhancedMicrophone( micIndex );
//			} else {
//				return Microphone.getMicrophone( micIndex );
//			}
		}


		private function speakerVolumeChanged(e:Event):void{
		}


		private function micVolumeChanged(e:Event):void{
			status( "micVolumeChanged" );
			var mic:Microphone = getMicrophone();
			if (mic){
				mic.gain = e.target.value;
				status("Setting mic volume to: " + e.target.value + "\n");
			}
		}

		// sending text message
		private function onSend():void{
//			var msg:String = textInput.text;
//			if (msg.length != 0 && outgoingStream){
//				textOutput.text += userName_str + ": " + msg + "\n";
//				outgoingStream.send("onIm", userName_str, msg);
//				textInput.text = "";
//			}
		}


		private function micChanged(event:Event):void{
			trace( "micChanged" );

			// set the new microphne values based on UI
			mic.gain = 80;
			mic.addEventListener(StatusEvent.STATUS, onDeviceStatus);
			mic.addEventListener(ActivityEvent.ACTIVITY, onDeviceActivity);

			handleCodecChange();

			if (_currentState == CALL_ESTABLISHED){
				outgoingStream.attachAudio(mic);
			}
		}

		private function changeCamera( index:int ):void{
			cameraIndex = index;
			localCamera = Camera.getCamera( cameraIndex.toString() );
			trace( "cameraChanged: "+ cameraIndex.toString() );
//			if (camera){
//				camera.setMode(320, 240, 15);
//				camera.setQuality(0, videoQualitySlider.value);
//			}

			// when user changes video device, we want to show preview
//			localVideoDisplay.attachCamera(camera);

			if (_currentState == CALL_ESTABLISHED){
				outgoingStream.attachCamera( localCamera );
			}
		}

		private function videoQualityChanged(e:Event = null):void{
//			var camera:Camera = Camera.getCamera(cameraIndex.toString());
//			if( camera ){
//				camera.setQuality(0, videoQualitySlider.value);
//				status("Setting camera quality to: " + videoQualitySlider.value + "\n");
//			}
		}

		private function onAudioMuted():void{
//			if (incomingStream){
//				incomingStream.receiveAudio(receiveAudioCheckbox.selected);
//			}
		}


		private function onVideoPaused():void{
//			if (incomingStream){
//				incomingStream.receiveVideo(receiveVideoCheckbox.selected);
//			}
		}


		private function handleCodecChange():void{
			trace( "handleCodecChange" );
//			var mic:Microphone = getMicrophone();
//			mic.codec = SoundCodec.SPEEX;
//			mic.framesPerPacket = 1;
//			mic.encodeQuality = 8;
//			mic.setSilenceLevel( 0 );


//			if (mic){
//				if( codecGroup.selection ){
//					if (codecGroup.selection.value == "speex"){
//						status("Setting audio codec to: speex\n");
//						//codecPropertyStack.selectedChild = speexProperties;
//						mic.codec = SoundCodec.SPEEX;
//						mic.framesPerPacket = 1;
//						mic.encodeQuality = int(speexQualitySelector.selectedItem);
//						//mic.encodeQuality = 8;
//						mic.setSilenceLevel(0);
//					} else {
//						status("Setting audio codec to: nellymoser \n");
//						//codecPropertyStack.selectedChild = nellymoserProperties;
//						mic.codec = SoundCodec.NELLYMOSER;
//						mic.rate =  int(nellymoserRateSelector.selectedItem);
//						//mic.rate = 22;
//						mic.setSilenceLevel(0);
//					}
//				} else {
//					status("codecGroup.selection が見つかりません\n");
//				}
//			} else {
//				status("マイクが見つかりません\n");
//			}
		}

		private function speexQuality(e:Event):void{
		}

		private function nellymoserRate(e:Event):void{
		}

		private function ring():void{
			ringer = new Sound();
			ringer.addEventListener("sampleData", ringTone);
			ringerChannel = ringer.play();
		}

		private function stopRing():void{
			if (ringerChannel){
				ringerChannel.stop();

				ringer.removeEventListener("sampleData", ringTone);

				ringer = null;
				ringerChannel = null;
			}
		}

		private function ringTone(event:SampleDataEvent):void{
			for (var c:int=0; c<8192; c++){
				var pos:Number = Number(c + event.position) / Number(6 * 44100);
				var frac:Number = pos - int(pos);
				var sample:Number;
				if (frac < 0.066){
  					 sample = 0.4 * Math.sin(2* Math.PI / (44100/784) * (Number(c + event.position)));
  				} else if (frac < 0.333){
  					sample = 0.2 * (Math.sin(2* Math.PI / (44100/646) * (Number(c + event.position)))
  						+ Math.sin(2* Math.PI / (44100/672) * (Number(c + event.position)))
  						+ Math.sin(2* Math.PI / (44100/1034) * (Number(c + event.position)))
  						+ Math.sin(2* Math.PI / (44100/1060) * (Number(c + event.position))));
  				} else {
  					sample = 0;
  				}
  				event.data.writeFloat(sample);
  				event.data.writeFloat(sample);
  			}
		}


		public function get sendVideo_bool():Boolean{
			return _sendVideo_bool;
		}
		public function set sendVideo_bool( val:Boolean ):void{
			_sendVideo_bool = val;
			startVideo();
		}

		public function get sendAudio_bool():Boolean{
			return _sendAudio_bool;
		}
		public function set sendAudio_bool( val:Boolean ):void{
			_sendAudio_bool = val;
			startAudio();
		}



	}
}

import flash.events.*;
import flash.display.*;
import jp.nium.utils.*;
import jp.noughts.cirrus.*;

class CirrusClient extends EventDispatcher{


	public function handleRemoteMouseEvent( obj:Object ):void{
		//trace( "handle  "+ obj.type );
		var event:MouseEvent = new MouseEvent( obj.type, true, false, obj.stageX, obj.stageY );
		dispatchEvent( event );
	}

	public function handleRemoteEvent( obj:Object ):void{
		//Logger.info( ObjectUtil.toString(obj) );
		var event:RemoteEvent = new RemoteEvent( obj.type, obj.data );
		dispatchEvent( event );
	}

}







