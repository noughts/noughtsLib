/*

HOW TO USE

var record_file:File = File.documentsDirectory.resolvePath( "test.avi" );
var mjpegBuilder:MotionJPEGBuilder = new MotionJPEGBuilder();
mjpegBuilder.setup( record_file, 320, 240, 10 );

// フレームを追加していきます
mjpegBuilder.addCanvasFrame( bitmapData );
mjpegBuilder.addCanvasFrame( bitmapData );
mjpegBuilder.addCanvasFrame( bitmapData );
...

// ファイナライズ
mjpegBuilder.finish( trace )


file を指定しなかったときは、finish後、mjpegBuilder.builder で ByteArray が取り出せます。


*/

package jp.noughts.media{
	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;

	import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
	import flash.filesystem.*;

	public class MotionJPEGBuilder {

		static private var AVIF_HASINDEX:uint = 0x00000010;
		var AVIIF_KEYFRAME = 0x00000010;
		static private var RateBase:uint = 1000000;
		static private var Verbose:Boolean = false;

		private var movieDesc:MovieDescription;
		private var frameList:Vector.<ByteArray>;
		private var moviLIST:MoviLIST
		private var headerLIST:HeaderLIST
		private var avi:AVIStruct;
		public var builder:BlobBuilder;
		private var file:File;

		private var jpegEncoderOptions:JPEGEncoderOptions = new JPEGEncoderOptions();

    	public function MotionJPEGBuilder(){
    		this.builder = new BlobBuilder();
    		this.movieDesc = new MovieDescription()
    		
    		avi = new AVIStruct();
    		this.headerLIST = new HeaderLIST();
    		moviLIST = new MoviLIST();
    		frameList = new Vector.<ByteArray>();
		}

		// ブラウザの blobBuilder を返す
		function getBlobBuilder() {
			return null;
		}



		public function setup( $file:File, frameWidth:uint, frameHeight:uint, fps:uint ){
			file = $file;
			this.movieDesc.w = frameWidth;
			this.movieDesc.h = frameHeight;
			this.movieDesc.fps = fps;
		}


		public function addCanvasFrame( bd:BitmapData ){
			var blob:ByteArray = bd.encode( bd.rect, jpegEncoderOptions );
			if( blob.length % 2 ){ // padding
				blob.writeByte(0);
			}

			var bsize:uint = blob.length;
			this.movieDesc.videoStreamSize += bsize;
			frameList.push( blob );
			
			if (this.movieDesc.maxJPEGSize < bsize) {
				this.movieDesc.maxJPEGSize = bsize;
			}
		}
		

		public function finish( onFinish:Function ):void{
			Logger.info( "動画ファイナライズ開始" )
			var streamSize = 0;
			this.moviLIST.aStreams = [];
			var frameCount:uint = frameList.length;
			var frameIndices:Vector.<FrameIndex> = new Vector.<FrameIndex>;
			var frOffset:int = 4; // 'movi' +0
			var IndexEntryOrder:Vector.<String> = new <String>['chId', 'dwFlags', 'dwOffset', 'dwLength'];
			for (var i = 0;i < frameCount; i++) {
				var frsize:int = addVideoStreamData( moviLIST.aStreams, frameList[i] );
				var frameIndex:FrameIndex = new FrameIndex()
				frameIndex.dwOffset = frOffset;
				frameIndex.dwLength = frsize - 8;
				frameIndex._order = IndexEntryOrder;
				frameIndices.push( frameIndex )
				
				frOffset += frsize;
				streamSize += frsize;
			};
			this.moviLIST.dwSize = streamSize + 4; // + 'movi'

			// stream header
			var frameDu:int = Math.floor(RateBase / this.movieDesc.fps);
			var strh:StreamHeader = new StreamHeader();
			strh.wRight  = this.movieDesc.w;
			strh.wBottom = this.movieDesc.h;
			strh.dwLength = this.frameList.length;
			strh.dwScale  = frameDu;

			var bi:BitmapHeader = new BitmapHeader();
			bi.dwWidth  = this.movieDesc.w;
			bi.dwHeight = this.movieDesc.h;
			bi.dwSizeImage = 3 * bi.dwWidth * bi.dwHeight;

			var strf:StreamFormat = new StreamFormat();
			strf.dwSize = bi.dwSize;
			strf.sContent = bi;
			
			var strl:StreamHeaderLIST = new StreamHeaderLIST();
			strl.dwSize = 4 + (strh.dwSize + 8) + (strf.dwSize + 8);
			strl.aList = [strh, strf];

			// AVI Header
			var avih:AVIMainHeader = new AVIMainHeader();
			avih.dwMicroSecPerFrame = frameDu;
			avih.dwMaxBytesPerSec = this.movieDesc.maxJPEGSize * this.movieDesc.fps;
			avih.dwTotalFrames = this.frameList.length;
			avih.dwWidth  = this.movieDesc.w;
			avih.dwHeight = this.movieDesc.h;
			avih.dwSuggestedBufferSize = 0;
			
			var hdrlSize:int = 4;
			hdrlSize += avih.dwSize + 8;
			hdrlSize += strl.dwSize + 8;
			this.headerLIST.dwSize = hdrlSize;
			this.headerLIST.aData = [avih, strl];

			var indexChunk = {
				chFourCC: 'idx1',
				dwSize: frameIndices.length * 16,
				aData: frameIndices,
				_order: ['chFourCC', 'dwSize', 'aData']
			};
			
			// AVI Container
			var aviSize:int = 0;
			aviSize += 8 + this.headerLIST.dwSize;
			aviSize += 8 + this.moviLIST.dwSize;
			aviSize += 8 + indexChunk.dwSize;
						
			avi.dwSize = aviSize + 4;
			avi.aData = [this.headerLIST, this.moviLIST, indexChunk];

			this.build(onFinish);
		}



		private function build( onFinish:Function ):void{
			Logger.info( "動画ビルド開始" )
			MotionJPEGBuilder.appendStruct( builder, avi );
			
			if( file ){
				Logger.info( "動画を書き出します" )
				var fs:FileStream = new FileStream();
				fs.open( file, FileMode.WRITE );
				fs.writeBytes( builder )
				fs.close();
				Logger.info( "動画書き出し完了" )
			} else {
				trace( "fileを指定してください。" )
			}
		}


		public function addVideoStreamData( list:Array, frameBuffer:ByteArray ):int{
			var stream:MoviStream = new MoviStream();
			stream.dwSize = frameBuffer.length;
			stream.handler = function(bb) {
				//bb.append(frameBuffer);
				bb.writeBytes( frameBuffer )
			};
			list.push( stream );
			return stream.dwSize + 8;
		}


		static private var _abtempDWORD
		static private var _u8tempDWORD:Array = new Array();
		static private var _abtempWORD
		static private var _u8tempWORD:Array = new Array();
		static private var _abtempBYTE
		static private var _u8tempBYTE:Array = new Array();

		static private function appendStruct( bb:BlobBuilder, s:Object, nest=null ){
			nest = nest || 0;
			if (!s._order) {
				throw "Structured data must have '_order'";
			}
			
			var od = s._order;
			var len:uint = od.length;
			for (var i = 0;i < len;i++) {
				var fieldName:String = od[i];
				var val:* = s[fieldName];
				if (Verbose) {
					trace("          ".substring(0,nest) + fieldName);
				}
				switch(fieldName.charAt(0)) {
					case 'b': // BYTE
						trace( bb )
						//_u8tempBYTE[0] = val;
						//bb.append(_abtempBYTE);
						bb.writeByte( val )
						break
					case 'c': // chars
						//trace( val )
						//bb.append(val);
						bb.writeMultiByte( val, "ascii" )
						break;
					case 'd': // DWORD
						//trace( val, val        & 0xff, (val >> 8)  & 0xff, (val >> 16) & 0xff, (val >> 24) & 0xff )
						//_u8tempDWORD[0] =  val        & 0xff;
						//_u8tempDWORD[1] = (val >> 8)  & 0xff;
						//_u8tempDWORD[2] = (val >> 16) & 0xff;
						//_u8tempDWORD[3] = (val >> 24) & 0xff;
						//bb.append(_abtempDWORD);
						bb.writeByte( val        & 0xff )
						bb.writeByte( (val >> 8)  & 0xff )
						bb.writeByte( (val >> 16) & 0xff )
						bb.writeByte( (val >> 24) & 0xff )
						break;
					case 'w': // WORD
						//_u8tempWORD[0] =  val        & 0xff;
						//_u8tempWORD[1] = (val >> 8)  & 0xff;
						//bb.append(_abtempWORD);
						bb.writeByte( val        & 0xff )
						bb.writeByte( (val >> 8) & 0xff )
						break
					case 'W': // WORD(BE)
						//_u8tempWORD[0] = (val >> 8)  & 0xff;
						//_u8tempWORD[1] =  val        & 0xff;
						//bb.append(_abtempWORD);
						bb.writeByte( (val >> 8) & 0xff )
						bb.writeByte( val        & 0xff )
						break
					case 'a': // Array of structured data
						var dlen:uint = val.length;
						for (var j = 0;j < dlen;j++) {
							MotionJPEGBuilder.appendStruct( bb, val[j], nest+1 );
						}
						break;
					case 'r': // Raw(ArrayBuffer)
						trace( val )
						bb.append(val);
						break;
					case 's': // Structured data
						MotionJPEGBuilder.appendStruct(bb, val, nest+1);
						break;
					case 'h': // Handler function
						val( bb );
						break;
					default:
						throw "Unknown data type: "+fieldName;
						break;
				}
			}
		}








	}
}


import flash.events.*;import flash.display.*;import flash.system.*;import flash.utils.*;import flash.net.*;import flash.media.*;import flash.geom.*;import flash.text.*;import flash.media.*;import flash.system.*;import flash.ui.*;import flash.external.ExternalInterface;import flash.filters.*;
class ArrayBuffer extends ByteArray{
	public function ArrayBuffer( length:uint ){
		this.length = length;
	}
}


class Uint8Array{
	public function Uint8Array( param:* ){

	}
}

class BlobBuilder extends ByteArray{
	public function BlobBuilder(){
	}

	public function append( ab:* ){
		trace( "append: "+ ab )
	}

	public function getBlob( mimetype:String ){
	}
}



class FileReader{
}



class Constants{
	static public const AVIF_HASINDEX:uint = 0x00000010
	static public const RATE_BASE:uint = 1000000;
	static public const AVIIF_KEYFRAME:uint = 0x00000010
}


class AVIStruct{
	var chRIFF:String = 'RIFF'
	var chFourCC:String = 'AVI '
	var dwSize:int = 0
	var aData:* = null
	var _order:Vector.<String> = new <String>['chRIFF', 'dwSize', 'chFourCC', 'aData']

}

class MoviLIST{
	var chLIST:String = 'LIST'
	var dwSize:int = 0
	var chFourCC:String = 'movi'
	var aStreams:Array = null
	var _order:Vector.<String> = new <String>['chLIST', 'dwSize', 'chFourCC', 'aStreams']

}

class MoviStream{
	var chType:String = '00dc'
	var dwSize:int = 0
	var handler:Function = null
	var _order:Vector.<String> = new <String>['chType', 'dwSize', 'handler']

}


class StreamHeaderLIST{
	var chLIST:String = 'LIST'
	var dwSize:int = 0
	var chFourCC:String = 'strl'
	var aList:* = null
	var _order:Vector.<String> = new <String>['chLIST', 'dwSize', 'chFourCC', 'aList']
}




class AVIMainHeader{
	var chFourCC:String = 'avih'
	var dwSize:int = 56

	var dwMicroSecPerFrame:int = 66666
	var dwMaxBytesPerSec:int = 1000
	var dwPaddingGranularity:int = 0
	var dwFlags:int = Constants.AVIF_HASINDEX
	// +16

	var dwTotalFrames:int = 1
	var dwInitialFrames:int = 0
	var dwStreams:int = 1
	var dwSuggestedBufferSize:int = 0
	// +32

	var dwWidth:int = 10
	var dwHeight:int = 20
	var dwReserved1:int = 0
	var dwReserved2:int = 0
	var dwReserved3:int = 0
	var dwReserved4:int = 0
	// +56

	var _order:Vector.<String> = new <String>[
		'chFourCC', 'dwSize',
		'dwMicroSecPerFrame', 'dwMaxBytesPerSec', 'dwPaddingGranularity', 'dwFlags',
		'dwTotalFrames', 'dwInitialFrames', 'dwStreams', 'dwSuggestedBufferSize',
		'dwWidth', 'dwHeight', 'dwReserved1', 'dwReserved2', 'dwReserved3', 'dwReserved4'
	]

}





class HeaderLIST{
	var chLIST:String = 'LIST'
	var dwSize:int = 0
	var chFourCC:String = 'hdrl'
	var aData:* = null
	var _order:Vector.<String> = new <String>['chLIST', 'dwSize', 'chFourCC', 'aData']

}




class StreamHeader{
	var chFourCC:String = 'strh'
	var dwSize:int = 56
	var chTypeFourCC:String = 'vids'
	var chHandlerFourCC:String = 'mjpg'

	var dwFlags:int = 0
	var wPriority:int = 0
	var wLanguage:int = 0
	var dwInitialFrames:int = 0
	var dwScale:int = 66666

	var dwRate:int = Constants.RATE_BASE
	var dwStart:int = 0
	var dwLength:int = 0
	var dwSuggestedBufferSize:int = 0

	var dwQuality:int = 10000
	var dwSampleSize:int = 0
	var wLeft:int = 0
	var wTop:int = 0
	var wRight:int = 0
	var wBottom:int = 0

	var _order:Vector.<String> = new <String>[
		 'chFourCC', 'dwSize', 'chTypeFourCC', 'chHandlerFourCC',
		 'dwFlags', 'wPriority', 'wLanguage', 'dwInitialFrames', 'dwScale',
		 'dwRate', 'dwStart', 'dwLength', 'dwSuggestedBufferSize',
		 'dwQuality', 'dwSampleSize', 'wLeft', 'wTop', 'wRight', 'wBottom'
		]

}




class StreamFormat{
	var chFourCC:String = 'strf'
	var dwSize:int = 0
	var sContent:* = null
	var _order:Vector.<String> = new <String>['chFourCC', 'dwSize', 'sContent']
}

class BitmapHeader{
	var dwSize:int =    40
	var dwWidth:int =   10
	var dwHeight:int =  20
	var wPlanes:int =   1
	var wBitcount:int = 24
	var chCompression:String = 'MJPG'
	var dwSizeImage:int = 600
	var dwXPelsPerMeter:int = 0
	var dwYPelsPerMeter:int = 0
	var dwClrUsed:int = 0
	var dwClrImportant:int = 0
	var _order:Vector.<String> = new <String>[
		'dwSize', 'dwWidth', 'dwHeight', 'wPlanes', 'wBitcount', 'chCompression', 
		'dwSizeImage', 'dwXPelsPerMeter', 'dwYPelsPerMeter', 'dwClrUsed', 'dwClrImportant'
	]
}



class MovieDescription{
	var w:int = 0
	var h:int =0
	var fps:int = 0
	var videoStreamSize:int = 0
	var maxJPEGSize:int = 0
}


class FrameIndex{
	var chId:String = '00dc'
	var dwFlags:int = Constants.AVIIF_KEYFRAME
	var dwOffset:int
	var dwLength:int
	var _order:Vector.<String>

}






