package jp.noughts.media{
	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;

	import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import flash.filesystem.*;

	public class MotionJPEGParser {

		private var bin:ByteArray;

    	public function MotionJPEGParser( $bin:ByteArray ){
    		bin = $bin;
    		bin.endian = Endian.LITTLE_ENDIAN;
    		//var riff:RIFF = new RIFF( bin )

    		var fcc:String = bin.readMultiByte( 4, "ascii" )
    		var size:uint = bin.readUnsignedInt()
    		var type:String = bin.readMultiByte( 4, "ascii" )
    		var data:ByteArray = new ByteArray();
    		bin.readBytes( data, 0, size-4 )
			var riff:LIST = new LIST( size, type, data )
			trace( riff )
		}






	}
}

import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;




class LIST{
	var fcc:String = "LIST"
	var size:uint;
	var type:String;
	var data:ByteArray;
	var data_array:Array

	public function LIST( $size:uint, $type:String, $data:ByteArray ){
		trace( "LISTを作成します。size="+ $size +" type="+ $type +" dataLength="+ $data.length )
		size = $size;
		type = $type;
		data = $data;
		if( data.length > 0 ){
			data_array = _parseData( data )
		}
	}

	public function toString():String{
		return "'"+ fcc +"' "+ size +" "+ type +" "+ data_array;
	}

	private function _parseData( ba:ByteArray ):Array{
		ba.position = 0;
		var out_array:Array = new Array();

		for( var i:int=0; i<100; i++ ){
			var result = _findTag( ba )
			if( result ){
				out_array.push( result )
			} else {
				break;
			}
		}
		return out_array;
	}

	private function _findTag( bin:ByteArray ):Object{
		trace( "findTag binLength="+ bin.length, bin.position )
		if( bin.length == bin.position ){
			return null;
		}
		bin.endian = Endian.LITTLE_ENDIAN;
		var out:Object = null;
		var fcc:String = bin.readMultiByte( 4, "ascii" )
		var size:uint = bin.readUnsignedInt()
		var data:ByteArray = new ByteArray();
		trace( fcc, bin.position, bin.length, size )

		if( fcc=="LIST" ){
			var type:String = bin.readMultiByte( 4, "ascii" )
			bin.readBytes( data, 0, size-4 )
			out = new LIST( size, type, data )
		} else {
			// チャンク
			bin.readBytes( data, 0, size )
			out = new Chunk( fcc, size, data )
		}
		return out;
	}
}


class Chunk{

	var fcc:String;
	var size:uint;
	var data:ByteArray

	public function Chunk( $fcc:String, $size:uint, $data:ByteArray ){
		trace( "Chunk を作成します。fcc="+ $fcc +" size="+ $size +" dataLength="+ $data.length )
		fcc = $fcc;
		size = $size;
		data = $data;
	}
}



class RIFF{
	var fcc:String;
	var fileSize:uint;
	var fileType:String;
	var data:Array;

	var bin:ByteArray
	var data_ba:ByteArray = new ByteArray();
	var hdrlList:LIST;
	var moviList:LIST;

	function RIFF( $bin:ByteArray ){
		bin = $bin;
		fcc = bin.readMultiByte( 4, "ascii" )
		fileSize = bin.readUnsignedInt()
		fileType = bin.readMultiByte( 4, "ascii" )
		bin.readBytes( data_ba, 0, fileSize-4 )
	}
}








