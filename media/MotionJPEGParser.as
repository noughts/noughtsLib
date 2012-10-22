package jp.noughts.media{
	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import mx.utils.*;
	import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import flash.filesystem.*;

	public class MotionJPEGParser {

		private var bin:ByteArray;

    	public function MotionJPEGParser( $bin:ByteArray ){
    		bin = $bin;
    		bin.endian = Endian.LITTLE_ENDIAN;

			var fcc:String = bin.readMultiByte( 4, "ascii" )
			var size:uint = bin.readUnsignedInt()
			var type:String = bin.readMultiByte( 4, "ascii" )
			var data:ByteArray = new ByteArray();
			bin.readBytes( data, 0, size-4 )
			var riff:LIST = new LIST( size, type, data )
			trace( ObjectUtil.toString( riff.data_array[2] ) )
		}






	}
}

import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;




class LIST{
	public var fcc:String = "LIST"
	public var size:uint;
	public var type:String;
	private var data:ByteArray;
	public var data_array:Array

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
		//trace( "findTag binLength="+ bin.length, bin.position )
		if( bin.length == bin.position ){
			return null;
		}


		bin.endian = Endian.LITTLE_ENDIAN;
		var out:Object = null;
		var fcc:String = bin.readMultiByte( 4, "ascii" )
		var size:uint = bin.readUnsignedInt()
		var data:ByteArray = new ByteArray();

		if( fcc=="LIST" ){
			// リスト
			var type:String = bin.readMultiByte( 4, "ascii" )
			bin.readBytes( data, 0, size-4 )
			out = new LIST( size, type, data )
		} else {
			// チャンク
			bin.readBytes( data, 0, size )
			switch( fcc ){
				case "idx1":
					out = new AviOldIndex( fcc, size, data )
					break;
				default:
					out = new Chunk( fcc, size, data )
			}
		}
		return out;
	}
}


class Chunk{

	public var fcc:String;
	var size:uint;
	var data:ByteArray

	public function Chunk( $fcc:String, $size:uint, $data:ByteArray ){
		trace( "Chunk を作成します。fcc="+ $fcc +" size="+ $size +" dataLength="+ $data.length )
		fcc = $fcc;
		size = $size;
		data = $data;
	}
}


class AviOldIndex extends Chunk{

	public var aIndex:Vector.<AviOldIndexEntry> = new Vector.<AviOldIndexEntry>();

	public function AviOldIndex( $fcc:String, $size:uint, $data:ByteArray ){
		super( $fcc, $size, $data )

		// インデックスパース
		data.endian = Endian.LITTLE_ENDIAN;
		var len:uint = data.length
		while( data.position < len ){
			trace( data.position, len )
			var cid:uint = data.readUnsignedInt()
			var flags:uint = data.readUnsignedInt()
			var offset:uint = data.readUnsignedInt()
			var size:uint = data.readUnsignedInt()
			aIndex.push( new AviOldIndexEntry(cid,flags,offset,size) )
		}
	}
}

class AviOldIndexEntry {
	public var dwChunkId:uint;
	public var dwFlags:uint;
	public var dwOffset:uint;
	public var dwSize:uint;
	public function AviOldIndexEntry( cid:uint, flags:uint, offset:uint, size:uint ){
		dwChunkId = cid;
		dwFlags = flags;
		dwOffset = offset;
		dwSize = size;
	}

}












