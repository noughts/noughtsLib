/*

var qp:QueryParser = new QueryParser( "http://example.com/?hoge=fuga&ooo=fff" )
trace( qp.hoge )// fuga


*/

package jp.noughts.utils
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	dynamic public class QueryParser{

    	public function QueryParser( url:String ){
    		var questionPos:int = url.indexOf("?")
    		var query_str:String =  url.substr( questionPos + 1 );
    		var vars:URLVariables = new URLVariables( query_str )
    		for( var p:String in vars ){
    			this[p] = vars[p]
    		}
		}
	}

}