package jp.noughts.utils{
	public class ArrayUtil{


		static public function diff( oldValues:Vector.<uint>, newValues:Vector.<uint> ):Vector.<Vector.<uint>>{
			var removed_vec:Vector.<uint> = new Vector.<uint>();
			var added_vec:Vector.<uint> = new Vector.<uint>();

			var oldLookup:Object = new Object();

			var i:int;

			for each( i in oldValues ){
			    oldLookup[i] = true;
			}       

			for each( i in newValues ){
			    if (oldLookup[i]) {
			        delete oldLookup[i];
			    } else {
			        added_vec.push( i );
			    }
			}

			for( var k:String in oldLookup ){
			    removed_vec.push( parseInt(k) );
			}
			var out_vec:Vector.<Vector.<uint>> = new Vector.<Vector>()
			out_vec.push( added_vec )
			out_vec.push( removed_vec )
			return out_vec
		}
	}
}