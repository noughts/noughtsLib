/*

TSV や CSV の表データをモデルデータとして扱えるようにするクラス

HOW TO USE

var data_str:String = "{google docs などからエクスポートしたタブ区切りデータ}";
var sheedData:SpreadSheet = new SpreadSheet( "tsv", data_str )

var lineData:Object = sheedData.getById( 42 )
trace( lineData["{列名}"] )


*/

package jp.noughts.utils{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	public class SpreadSheet extends Sprite{
    	
		private var _data:Array
		public function get data():Array{ return _data }

		public function SpreadSheet( mode:String, data_str ){
			switch( mode ){
				case "tsv":
					_data = parseTSV( data_str )
					break;
				default:
					trace( "SpreadSheet 対応していないモードです。" )
			}
		}


		public function findById( id:uint ):Object{
			var id_str:String = String( id );
			var out:Object;
			var len:uint = data.length;
			var _d:Object;
			for( var i:int=0; i<len; i++ ){
				_d = data[i];
				if( _d["id"] == id_str ){
					out = _d;
					break;
				}
			}
			return out;
		}



		public function parseTSV( data_str:String ):Array{
			var lines:Array = data_str.split("\n");
			var titleLine_str:String = lines.shift();
			var titles:Array = titleLine_str.split("\t")
			
			// 行名の中に ID, Id があれば id にする。
			titles.forEach( function( item:*, index:int, array:Array ):void{
				if( item=="ID" || item=="Id" ){
					array[index] = "id";
				}
			} );

			var data:Array = [];
			for each( var line:String in lines ){
				var dataLine:Array = line.split( "\t" );
				var _temp:Object = new Object();
				for( var i:int=0; i<titles.length; i++ ){
					_temp[titles[i]] = dataLine[i];
				}
				data.push( _temp )
			}
			return data;			
		}

	}

}