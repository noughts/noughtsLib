package jp.noughts.cocoafish.sdk {
	import jp.noughts.cocoafish.constants.Constants;
	import flash.utils.*;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	//import mx.collections.Array;
	//import mx.utils.URLUtil;
	import jp.nium.utils.ArrayUtil;
	import jp.nium.core.debug.Logger
	
	import org.iotashan.oauth.IOAuthSignatureMethod;
	import org.iotashan.oauth.OAuthConsumer;
	import org.iotashan.oauth.OAuthRequest;
	import org.iotashan.oauth.OAuthSignatureMethod_HMAC_SHA1;
	
	public class Cocoafish {
		private var appKey:String = null;
		private var sessionId:String = null;
		private var consumer:OAuthConsumer = null;
		private var listeners:Array = null;
		private var apiBaseURL:String = null;
		
		public function Cocoafish(key:String, oauthSecret:String = "", baseURL:String = null) {
			if(oauthSecret == "") {
				this.appKey = key;
			} else {
				consumer = new OAuthConsumer(key, oauthSecret);
			}
			if(baseURL) {
				apiBaseURL = baseURL;
			} else {
				apiBaseURL = Constants.API_BASE_URL;
			}
		}

		private function _uploadData( url:String, data:ByteArray, callbackFunc:Function ):void{
			var req:URLRequest = new URLRequest( url )
			req.method = "POST"
			req.data = data;

			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			//Request complete
			loader.addEventListener(Event.COMPLETE, function():void{
				completeCallback( loader.data, callbackFunc );
			});
			loader.load( req )

		}
		
		public function sendRequest(url:String, method:String, data:Object, callback:Object, useSecure:Object = null):CCRequest {
			var isSecure:Boolean = true;
			var callbackFunc:Function = null;
			
			if(callback is Boolean) {
				isSecure = callback as Boolean;
				callbackFunc = useSecure as Function;
			} else {
				callbackFunc = callback as Function;
				if(useSecure != null)
					isSecure = useSecure as Boolean;
			}
			
			var baseURL:String = null;
			if(isSecure) {
				baseURL = Constants.API_SECURE + apiBaseURL + "/";
			} else {
				baseURL = Constants.API_NON_SECURE + apiBaseURL + "/";
			}
			
			var reqURL:String = baseURL + url;

			if( data is ByteArray ){
				_uploadData( reqURL, data as ByteArray, callbackFunc );
				return null;
			}
			
			var httpMethod:String = null;
			if(method == URLRequestMethod.DELETE) {
				httpMethod = URLRequestMethod.GET;
			} else if (method == URLRequestMethod.PUT) {
				httpMethod = URLRequestMethod.POST;
			} else {
				httpMethod = method;
			}
			
			//append suppress_response_codes=true
			if(data == null) {
				data = new Object();
			}
			if(!data.hasOwnProperty(Constants.SUPPRESS_RESPONSE_KEY)) {
				//data[Constants.SUPPRESS_RESPONSE_KEY] = true;
			}
			
			var photoRef:FileReference = null;
			var attrName:String = Constants.PHOTO_KEY;
			if(data != null) {
				photoRef = data.photoHoge;
				if(photoRef != null) {
					delete(data.photoHoge);
					attrName= Constants.PHOTO_KEY;
				} else {
					photoRef = data.file;
					if(photoRef != null) {
						delete(data.file);
						attrName= Constants.FILE_KEY;
					}
				}
			}
			
			var request:URLRequest = null;
			if(appKey != null) {
				//append session id
				if(this.sessionId != null) {
					//reqURL += Constants.PARAMETER_DELIMITER + Constants.SESSION_ID + Constants.PARAMETER_EQUAL + this.sessionId;
				}
				request = new URLRequest(reqURL);
			} else if(consumer != null) {
				if(photoRef != null) {
					request = this.buildOAuthRequest(reqURL, httpMethod, null);
				} else {
					if(this.sessionId != null) {
						data[Constants.SESSION_ID] = this.sessionId;
					}
					request = this.buildOAuthRequest(reqURL, httpMethod, data);
				}
			} else {
				//TODO: error handling
			}
			
			request.requestHeaders.push(new URLRequestHeader(Constants.ACCEPT_KEY, Constants.ACCEPT_VALUE));
			
			if(photoRef != null) {
				request.requestHeaders.push(new URLRequestHeader(Constants.CACHE_CTRL_KEY, Constants.CACHE_CTRL_VALUE));
				request.method = URLRequestMethod.POST;
				//append session id
				if(this.sessionId != null) {
					if(request.url.indexOf(Constants.SESSION_ID) == -1) {
						//request.url += Constants.PARAMETER_DELIMITER + Constants.SESSION_ID + Constants.PARAMETER_EQUAL + this.sessionId;
					}
				}
				/*
				var fileType:String = photoRef.type;
				if(fileType == null) {
					fileType = extractFileType(photoRef.name);	//workaround for Mac issue
				}
				if(fileType != null) {
					fileType = Constants.IMAGE_KEY + "/" + fileType;
				}
				*/
				var urlVars:URLVariables = new URLVariables();
				for(var name:String in data) {
					urlVars[name] = data[name];
				}
				request.data = urlVars;
				
				//Request complete
				photoRef.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, function(event:DataEvent):void{
					completeCallback(event.data, callbackFunc);
				});
				
				//IO Error
				photoRef.addEventListener(IOErrorEvent.IO_ERROR, function(event:Event):void {
					errorCallback(event, callbackFunc);
				});
				
				//Register upload progress listeners
				registerProgressListeners(photoRef);
				
				photoRef.upload(request, attrName);
				return new CCRequest(photoRef);
			} else {
				var loader:URLLoader = new URLLoader();
				request.method = httpMethod;
				if(data != null) {
					if(data[Constants.SESSION_ID])
						delete(data[Constants.SESSION_ID]);
					var params:String = getURLParameters(data);
					if(params != null && params.length > 0) {
						if(httpMethod == URLRequestMethod.GET) {
							request.url += "?" + params;
						} else {
							request.data = params;
						}
					}
				}
				loader.dataFormat = URLLoaderDataFormat.TEXT;
				
				//append session id
				//if(this.sessionId != null) {
				//	if(request.url.indexOf(Constants.SESSION_ID) == -1) {
				//		if(request.url.indexOf(Constants.PARAMETER_QUESTION) != -1) {
				//			request.url += Constants.PARAMETER_DELIMITER + Constants.SESSION_ID + Constants.PARAMETER_EQUAL + this.sessionId;
				//		} else {
				//			request.url += Constants.PARAMETER_QUESTION + Constants.SESSION_ID + Constants.PARAMETER_EQUAL + this.sessionId;
				//		}
				//	}
				//}
				
				//Request complete
				loader.addEventListener(Event.COMPLETE, function():void{
					//trace("cocoafish complete!!!")
					completeCallback(loader.data, callbackFunc);
				});
				
				//IO Error
				loader.addEventListener(IOErrorEvent.IO_ERROR, function(event:Event):void {
					//trace("cocoafish io_error!!!")
					errorCallback(event, callbackFunc);
				});
				
				//send request
				Logger.info( "Cocoafish request start: url= "+ request.url )
				loader.load(request);
				return new CCRequest(loader);
			}
		}
		
		public function addProgressListener(listener:Function):void {
			if(listeners == null) {
				listeners = new Array();
			}
			listeners.push(listener);
		}
		
		public function removeProgressListener(listener:Function):void {
			if(listeners != null) {
				var i:int = ArrayUtil.getItemIndex( listeners, listener );
				listeners.splice( i, 1 );
				//listeners.removeItem(listener);
			}
		}
		
		private function registerProgressListeners(fileRef:FileReference):void {
			if(listeners != null) {
				for(var i:int = 0; i< listeners.length; i++) {
					fileRef.addEventListener(ProgressEvent.PROGRESS, listeners[i] as Function);
				}
			}
		}
		
		private function buildOAuthRequest(url:String, method:String, params:Object) : URLRequest {
			//append session id
			if(this.sessionId != null) {
				if(params == null) {
					params = new Object();
				}
				params[Constants.SESSION_ID] = this.sessionId;
			}
			
			var oauthRequest:OAuthRequest = new OAuthRequest(method, url, params, consumer, null);
			var signatureMethod:IOAuthSignatureMethod = new OAuthSignatureMethod_HMAC_SHA1();
			var oauthURL:String = oauthRequest.buildRequest(signatureMethod, OAuthRequest.RESULT_TYPE_URL_STRING);
			var request:URLRequest = new URLRequest(oauthURL);
			return request;
		}
		
		private function completeCallback(data:String, callback:Function):void {
			if(data != null) {
				//var json:Object = com.adobe.serialization.json.JSON.decode(data);
				try{
					var json:Object = JSON.parse( data );
				} catch( e:Error ){
					//trace( data );
					//trace( e );
					return;
				}
				var sessionId:String = parseSessionId(json);
				if(sessionId != null) {
					setSessionId(sessionId);
				}
				//json.json = data;
				callback(json);
			} else {
				callback(new Object());
			}
		}
		
		private function errorCallback(event:Event, callback:Function):void {
			callback(event);
		}
		
		private function parseSessionId(data:Object):String {
			if(data != null) {
				var meta:Object = data.meta;
				if(meta != null) {
					var sessionId:String = meta.session_id;
					if(sessionId != null) {
						return sessionId;
					}
				}
			}
			return null;
		}
		
		public function setSessionId(sessionId:String):void {
			this.sessionId = sessionId;
		}
		
		public function getSessionId():String {
			return this.sessionId;
		}
		
		/*
		private function extractFileType(fileName:String):String {
			var extensionIndex:Number = fileName.lastIndexOf(".");
			if (extensionIndex == -1) {
				return null;
			} else {
				return fileName.substr(extensionIndex + 1 ,fileName.length);
			}
		}
		*/
		
		private function getURLParameters(data:Object):String {
			var params:String = URLUtil.objectToString(data, Constants.PARAMETER_DELIMITER);
			return params;
		}
	}
}






/**
 *  The URLUtil class is a static class with methods for working with
 *  full and relative URLs within Flex.
 *  
 *  @see mx.managers.BrowserManager
 *  
 *  @langversion 3.0
 *  @playerversion Flash 9
 *  @playerversion AIR 1.1
 *  @productversion Flex 3
 */
class URLUtil{
    //--------------------------------------------------------------------------
    //
    // Private Static Constants
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private 
     */
    private static const SQUARE_BRACKET_LEFT:String = "]";
    private static const SQUARE_BRACKET_RIGHT:String = "[";
    private static const SQUARE_BRACKET_LEFT_ENCODED:String = encodeURIComponent(SQUARE_BRACKET_LEFT);
    private static const SQUARE_BRACKET_RIGHT_ENCODED:String = encodeURIComponent(SQUARE_BRACKET_RIGHT);
    
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    /**
     *  @private
     */
    public function URLUtil()
    {
        super();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Class methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Returns the domain and port information from the specified URL.
     *  
     *  @param url The URL to analyze.
     *  @return The server name and port of the specified URL.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function getServerNameWithPort(url:String):String
    {
        // Find first slash; second is +1, start 1 after.
        var start:int = url.indexOf("/") + 2;
        var length:int = url.indexOf("/", start);
        return length == -1 ? url.substring(start) : url.substring(start, length);
    }
    
    /**
     *  Returns the server name from the specified URL.
     *  
     *  @param url The URL to analyze.
     *  @return The server name of the specified URL.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function getServerName(url:String):String
    {
        var sp:String = getServerNameWithPort(url);
        
        // If IPv6 is in use, start looking after the square bracket.
        var delim:int = URLUtil.indexOfLeftSquareBracket(sp);
        delim = (delim > -1)? sp.indexOf(":", delim) : sp.indexOf(":");   
        
        if (delim > 0)
            sp = sp.substring(0, delim);
        return sp;
    }
    
    /**
     *  Returns the port number from the specified URL.
     *  
     *  @param url The URL to analyze.
     *  @return The port number of the specified URL.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function getPort(url:String):uint
    {
        var sp:String = getServerNameWithPort(url);
        // If IPv6 is in use, start looking after the square bracket.
        var delim:int = URLUtil.indexOfLeftSquareBracket(sp);
        delim = (delim > -1)? sp.indexOf(":", delim) : sp.indexOf(":");          
        var port:uint = 0;
        if (delim > 0)
        {
            var p:Number = Number(sp.substring(delim + 1));
            if (!isNaN(p))
                port = int(p);
        }
        
        return port;
    }
    
    /**
     *  Converts a potentially relative URL to a fully-qualified URL.
     *  If the URL is not relative, it is returned as is.
     *  If the URL starts with a slash, the host and port
     *  from the root URL are prepended.
     *  Otherwise, the host, port, and path are prepended.
     *
     *  @param rootURL URL used to resolve the URL specified by the <code>url</code> parameter, if <code>url</code> is relative.
     *  @param url URL to convert.
     *
     *  @return Fully-qualified URL.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function getFullURL(rootURL:String, url:String):String
    {
        if (url != null && !URLUtil.isHttpURL(url))
        {
            if (url.indexOf("./") == 0)
            {
                url = url.substring(2);
            }
            if (URLUtil.isHttpURL(rootURL))
            {
                var slashPos:Number;
                
                if (url.charAt(0) == '/')
                {
                    // non-relative path, "/dev/foo.bar".
                    slashPos = rootURL.indexOf("/", 8);
                    if (slashPos == -1)
                        slashPos = rootURL.length;
                }
                else
                {
                    // relative path, "dev/foo.bar".
                    slashPos = rootURL.lastIndexOf("/") + 1;
                    if (slashPos <= 8)
                    {
                        rootURL += "/";
                        slashPos = rootURL.length;
                    }
                }
                
                if (slashPos > 0)
                    url = rootURL.substring(0, slashPos) + url;
            }
        }
        
        return url;
    }
    
    // Note: The following code was copied from Flash Remoting's
    // NetServices client components.
    // It is reproduced here to keep the services APIs
    // independent of the deprecated NetServices code.
    // Note that it capitalizes any use of URL in method or class names.
    
    /**
     *  Determines if the URL uses the HTTP, HTTPS, or RTMP protocol. 
     *
     *  @param url The URL to analyze.
     * 
     *  @return <code>true</code> if the URL starts with "http://", "https://", or "rtmp://".
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function isHttpURL(url:String):Boolean
    {
        return url != null &&
            (url.indexOf("http://") == 0 ||
                url.indexOf("https://") == 0);
    }
    
    /**
     *  Determines if the URL uses the secure HTTPS protocol. 
     *
     *  @param url The URL to analyze.
     * 
     *  @return <code>true</code> if the URL starts with "https://".
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function isHttpsURL(url:String):Boolean
    {
        return url != null && url.indexOf("https://") == 0;
    }
    
    /**
     *  Returns the protocol section of the specified URL.
     *  The following examples show what is returned based on different URLs:
     *  
     *  <pre>
     *  getProtocol("https://localhost:2700/") returns "https"
     *  getProtocol("rtmp://www.myCompany.com/myMainDirectory/groupChatApp/HelpDesk") returns "rtmp"
     *  getProtocol("rtmpt:/sharedWhiteboardApp/June2002") returns "rtmpt"
     *  getProtocol("rtmp::1234/chatApp/room_name") returns "rtmp"
     *  </pre>
     *
     *  @param url String containing the URL to parse.
     *
     *  @return The protocol or an empty String if no protocol is specified.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function getProtocol(url:String):String
    {
        var slash:int = url.indexOf("/");
        var indx:int = url.indexOf(":/");
        if (indx > -1 && indx < slash)
        {
            return url.substring(0, indx);
        }
        else
        {
            indx = url.indexOf("::");
            if (indx > -1 && indx < slash)
                return url.substring(0, indx);
        }
        
        return "";
    }
    
    /**
     *  Replaces the protocol of the
     *  specified URI with the given protocol.
     *
     *  @param uri String containing the URI in which the protocol
     *  needs to be replaced.
     *
     *  @param newProtocol String containing the new protocol to use.
     *
     *  @return The URI with the protocol replaced,
     *  or an empty String if the URI does not contain a protocol.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function replaceProtocol(uri:String,
                                           newProtocol:String):String
    {
        return uri.replace(getProtocol(uri), newProtocol);
    }
    
    /**
     *  Returns a new String with the port replaced with the specified port.
     *  If there is no port in the specified URI, the port is inserted.
     *  This method expects that a protocol has been specified within the URI.
     *
     *  @param uri String containing the URI in which the port is replaced.
     *  @param newPort uint containing the new port to subsitute.
     *
     *  @return The URI with the new port.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function replacePort(uri:String, newPort:uint):String
    {
        var result:String = "";
        
        // First, determine if IPv6 is in use by looking for square bracket
        var indx:int = uri.indexOf("]");
        
        // If IPv6 is not in use, reset indx to the first colon
        if (indx == -1)
            indx = uri.indexOf(":");
        
        var portStart:int = uri.indexOf(":", indx+1);
        var portEnd:int;
        
        // If we have a port
        if (portStart > -1)
        {
            portStart++; // move past the ":"
            portEnd = uri.indexOf("/", portStart);
            //@TODO: need to throw an invalid uri here if no slash was found
            result = uri.substring(0, portStart) +
                newPort.toString() +
                uri.substring(portEnd, uri.length);
        }
        else
        {
            // Insert the specified port
            portEnd = uri.indexOf("/", indx);
            if (portEnd > -1)
            {
                // Look to see if we have protocol://host:port/
                // if not then we must have protocol:/relative-path
                if (uri.charAt(portEnd+1) == "/")
                    portEnd = uri.indexOf("/", portEnd + 2);
                
                if (portEnd > 0)
                {
                    result = uri.substring(0, portEnd) +
                        ":"+ newPort.toString() +
                        uri.substring(portEnd, uri.length);
                }
                else
                {
                    result = uri + ":" + newPort.toString();
                }
            }
            else
            {
                result = uri + ":"+ newPort.toString();
            }
        }
        
        return result;
    }
    
    

    /**
     *  Given a url, determines whether the url contains the server.name and
     *  server.port tokens.
     *
     *  @param url A url string. 
     * 
     *  @return <code>true</code> if the url contains server.name and server.port tokens.
     *
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */ 
    public static function hasTokens(url:String):Boolean
    {
        if (url == null || url == "")
            return false;
        if (url.indexOf(SERVER_NAME_TOKEN) > 0)
            return true;
        if (url.indexOf(SERVER_PORT_TOKEN) > 0)
            return true;
        return false;
    }
    

    
    /**
     *  The pattern in the String that is passed to the <code>replaceTokens()</code> method that 
     *  is replaced by the application's server name.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static const SERVER_NAME_TOKEN:String = "{server.name}";
    
    /**
     *  The pattern in the String that is passed to the <code>replaceTokens()</code> method that 
     *  is replaced by the application's port.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static const SERVER_PORT_TOKEN:String = "{server.port}";
    
    /**
     *  Enumerates an object's dynamic properties (by using a <code>for..in</code> loop)
     *  and returns a String. You typically use this method to convert an ActionScript object to a String that you then append to the end of a URL.
     *  By default, invalid URL characters are URL-encoded (converted to the <code>%XX</code> format).
     *
     *  <p>For example:
     *  <pre>
     *  var o:Object = { name: "Alex", age: 21 };
     *  var s:String = URLUtil.objectToString(o,";",true);
     *  trace(s);
     *  </pre>
     *  Prints "name=Alex;age=21" to the trace log.
     *  </p>
     *  
     *  @param object The object to convert to a String.
     *  @param separator The character that separates each of the object's <code>property:value</code> pair in the String.
     *  @param encodeURL Whether or not to URL-encode the String.
     *  
     *  @return The object that was passed to the method.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function objectToString(object:Object, separator:String=';',
                                          encodeURL:Boolean = true):String
    {
        var s:String = internalObjectToString(object, separator, null, encodeURL);
        return s;
    }
    
    private static function indexOfLeftSquareBracket(value:String):int
    {
        var delim:int = value.indexOf(SQUARE_BRACKET_LEFT);
        if (delim == -1)
            delim = value.indexOf(SQUARE_BRACKET_LEFT_ENCODED);
        return delim;
    }
    
    private static function internalObjectToString(object:Object, separator:String, prefix:String, encodeURL:Boolean):String
    {
        var s:String = "";
        var first:Boolean = true;
        
        for (var p:String in object)
        {
            if (first)
            {
                first = false;
            }
            else
                s += separator;
            
            var value:Object = object[p];
            var name:String = prefix ? prefix + "." + p : p;
            if (encodeURL)
                name = encodeURIComponent(name);
            
            if (value is String)
            {
                s += name + '=' + (encodeURL ? encodeURIComponent(value as String) : value);
            }
            else if (value is Number)
            {
                value = value.toString();
                if (encodeURL)
                    value = encodeURIComponent(value as String);
                
                s += name + '=' + value;
            }
            else if (value is Boolean)
            {
                s += name + '=' + (value ? "true" : "false");
            }
            else
            {
                if (value is Array)
                {
                    s += internalArrayToString(value as Array, separator, name, encodeURL);
                }
                else // object
                {
                    s += internalObjectToString(value, separator, name, encodeURL);
                }
            }
        }
        return s;
    }
    
    private static function replaceEncodedSquareBrackets(value:String):String
    {
        var rightIndex:int = value.indexOf(SQUARE_BRACKET_RIGHT_ENCODED);
        if (rightIndex > -1)
        {
            value = value.replace(SQUARE_BRACKET_RIGHT_ENCODED, SQUARE_BRACKET_RIGHT);
            var leftIndex:int = value.indexOf(SQUARE_BRACKET_LEFT_ENCODED);
            if (leftIndex > -1)
                value = value.replace(SQUARE_BRACKET_LEFT_ENCODED, SQUARE_BRACKET_LEFT);
        }
        return value;
    }
    
    private static function internalArrayToString(array:Array, separator:String, prefix:String, encodeURL:Boolean):String
    {
        var s:String = "";
        var first:Boolean = true;
        
        var n:int = array.length;
        for (var i:int = 0; i < n; i++)
        {
            if (first)
            {
                first = false;
            }
            else
                s += separator;
            
            var value:Object = array[i];
            var name:String = prefix + "." + i;
            if (encodeURL)
                name = encodeURIComponent(name);
            
            if (value is String)
            {
                s += name + '=' + (encodeURL ? encodeURIComponent(value as String) : value);
            }
            else if (value is Number)
            {
                value = value.toString();
                if (encodeURL)
                    value = encodeURIComponent(value as String);
                
                s += name + '=' + value;
            }
            else if (value is Boolean)
            {
                s += name + '=' + (value ? "true" : "false");
            }
            else
            {
                if (value is Array)
                {
                    s += internalArrayToString(value as Array, separator, name, encodeURL);
                }
                else // object
                {
                    s += internalObjectToString(value, separator, name, encodeURL);
                }
            }
        }
        return s;
    }
    
    /**
     *  Returns an object from a String. The String contains <code>name=value</code> pairs, which become dynamic properties
     *  of the returned object. These property pairs are separated by the specified <code>separator</code>.
     *  This method converts Numbers and Booleans, Arrays (defined by "[]"), 
     *  and sub-objects (defined by "{}"). By default, URL patterns of the format <code>%XX</code> are converted
     *  to the appropriate String character.
     *
     *  <p>For example:
     *  <pre>
     *  var s:String = "name=Alex;age=21";
     *  var o:Object = URLUtil.stringToObject(s, ";", true);
     *  </pre>
     *  
     *  Returns the object: <code>{ name: "Alex", age: 21 }</code>.
     *  </p>
     *  
     *  @param string The String to convert to an object.
     *  @param separator The character that separates <code>name=value</code> pairs in the String.
     *  @param decodeURL Whether or not to decode URL-encoded characters in the String.
     * 
     *  @return The object containing properties and values extracted from the String passed to this method.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function stringToObject(string:String, separator:String = ";",
                                          decodeURL:Boolean = true):Object
    {
        var o:Object = {};
        
        var arr:Array = string.split(separator);
        
        // if someone has a name or value that contains the separator 
        // this will not work correctly, nor will it work well if there are 
        // '=' or '.' in the name or value
        
        var n:int = arr.length;
        for (var i:int = 0; i < n; i++)
        {
            var pieces:Array = arr[i].split('=');
            var name:String = pieces[0];
            if (decodeURL)
                name = decodeURIComponent(name);
            
            var value:Object = pieces[1];
            if (decodeURL)
                value = decodeURIComponent(value as String);
            
            if (value == "true")
                value = true;
            else if (value == "false")
                value = false;
            else 
            {
                var temp:Object = int(value);
                if (temp.toString() == value)
                    value = temp;
                else
                {
                    temp = Number(value)
                    if (temp.toString() == value)
                        value = temp;
                }
            }
            
            var obj:Object = o;
            
            pieces = name.split('.');
            var m:int = pieces.length;
            for (var j:int = 0; j < m - 1; j++)
            {
                var prop:String = pieces[j];
                if (obj[prop] == null && j < m - 1)
                {
                    var subProp:String = pieces[j + 1];
                    var idx:Object = int(subProp);
                    if (idx.toString() == subProp)
                        obj[prop] = [];
                    else
                        obj[prop] = {};
                }
                obj = obj[prop];
            }
            obj[pieces[j]] = value;
        }
        
        return o;
    }
    
    // Reusable reg-exp for token replacement. The . means any char, so this means
    // we should handle server.name and server-name, etc...
    private static const SERVER_NAME_REGEX:RegExp = new RegExp("\\{server.name\\}", "g");
    private static const SERVER_PORT_REGEX:RegExp = new RegExp("\\{server.port\\}", "g");    
}