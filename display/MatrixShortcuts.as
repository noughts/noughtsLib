package jp.noughts.display
{
	import caurina.transitions.Tweener;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.display.DisplayObject;
	
	/**
	 * sketchbook.external.tweener.MatrixShortcuts
	 * List of special matrix properties (normal and splitter properties) for the Tweener class
	 * 
	 * When you call init() method. This class register following special properties to the Tweener.
	 * 
	 * <dl>
	 * 	<dt>_matrix_a</dt><dd>Controls transform.matrix.a</dd>
	 *  <dt>_matrix_b</dt><dd>Controls transform.matrix.b</dd>
	 *  <dt>_matrix_c</dt><dd>Controls transform.matrix.c</dd>
	 *  <dt>_matrix_d</dt><dd>Controls transform.matrix.d</dd>
	 *  <dt>_matrix_tx</dt><dd>Controls transform.matrix.tx</dd>
	 *  <dt>_matrix_ty</dt><dd>Controls transform.matrix.ty</dd>
	 *  <dt>_matrix</dt><dd>Controls transform.matrix</dd>
	 *  <dt>_global_matrix_a</dt><dd>Controls transform.matrix.a with Global Coordinate</dd>
	 *  <dt>_global_matrix_b</dt><dd>Controls transform.matrix.b with Global Coordinate</dd>
	 *  <dt>_global_matrix_c</dt><dd>Controls transform.matrix.c with Global Coordinate</dd>
	 *  <dt>_global_matrix_d</dt><dd>Controls transform.matrix.d with Global Coordinate</dd>
	 *  <dt>_global_matrix_tx</dt><dd>Controls transform.matrix.tx with Global Coordinate</dd>
	 *  <dt>_global_matrix_ty</dt><dd>Controls transform.matrix.ty with Global Coordinate</dd>
	 *  <dt>_global_matrix</dt><dd>Controls transform.matrix with Global Coordinate</dd>
	 *  <dt>_global_x</dt><dd>Controls DisplayObject's x with Global Coordinate</dd>
	 *  <dt>_global_y</dt><dd>Controls DisplayObject's y with Global Coordinate</dd>
	 *  <dt>_global_rotation</dt><dd>Controls DisplayObject's rotation with Global Coordinate</dd>
	 *  <dt>_global_scaleX</dt><dd>Controls DisplayObject's scaleX with Global Coordinate</dd>
	 *  <dt>_global_scaleY</dt><dd>Controls DisplayObject's scaleY with Global Coordinate</dd>
	 *  <dt>_global_scale</dt><dd>Controls DisplayObject's both scaleX and scaleY with Global Coordinate</dd>
	 * </dl>
	 * 
	 * @example following code move DisplayObject to global coordinate (100,100).
	 * <listing version="3.0">MatrixShortcuts.init();
	 * Tweener.addTween(myDisplayObject,{time:1, 
	 * _global_x:100,
	 * _global_y:100});</listing>
	 *
	 * @author		Takayuki Fukatsu, fladdict.net
	 * @version		1.0.0
	 * 
	 */
	public class MatrixShortcuts
	{
		/**
		 * Initialization method.
		 * This method register some special properties to the Tweener.
		 */
		public static function init(): void {
			Tweener.registerSpecialProperty("_matrix_a", 		_matrix_prop_get, _matrix_prop_set, ["a"]);
			Tweener.registerSpecialProperty("_matrix_b", 		_matrix_prop_get, _matrix_prop_set, ["b"]);
			Tweener.registerSpecialProperty("_matrix_c", 		_matrix_prop_get, _matrix_prop_set, ["c"]);
			Tweener.registerSpecialProperty("_matrix_d", 		_matrix_prop_get, _matrix_prop_set, ["d"]);
			Tweener.registerSpecialProperty("_matrix_tx",	 	_matrix_prop_get, _matrix_prop_set, ["tx"]);
			Tweener.registerSpecialProperty("_matrix_ty", 		_matrix_prop_get, _matrix_prop_set, ["ty"]);
			Tweener.registerSpecialPropertySplitter("_matrix", _matrix_splitter);
			
			Tweener.registerSpecialProperty("_global_matrix_a", 		_global_matrix_prop_get, _global_matrix_prop_set, ["a"]);
			Tweener.registerSpecialProperty("_global_matrix_b", 		_global_matrix_prop_get, _global_matrix_prop_set, ["b"]);
			Tweener.registerSpecialProperty("_global_matrix_c", 		_global_matrix_prop_get, _global_matrix_prop_set, ["c"]);
			Tweener.registerSpecialProperty("_global_matrix_d", 		_global_matrix_prop_get, _global_matrix_prop_set, ["d"]);
			Tweener.registerSpecialProperty("_global_matrix_tx", 		_global_matrix_prop_get, _global_matrix_prop_set, ["tx"]);
			Tweener.registerSpecialProperty("_global_matrix_ty", 		_global_matrix_prop_get, _global_matrix_prop_set, ["ty"]);
			Tweener.registerSpecialPropertySplitter("_global_matrix", _global_matrix_splitter);
			
			Tweener.registerSpecialProperty("_global_x", 				_global_xy_prop_get, 		_global_xy_prop_set, ["x"]);
			Tweener.registerSpecialProperty("_global_y", 				_global_xy_prop_get, 		_global_xy_prop_set, ["y"]);
			Tweener.registerSpecialProperty("_global_rotation", 		_global_rotation_prop_get, 	_global_rotation_prop_set);
			Tweener.registerSpecialProperty("_global_scaleX", 		_global_scale_prop_get, 	_global_scale_prop_set, ["scaleX"]);
			Tweener.registerSpecialProperty("_global_scaleY", 		_global_scale_prop_get, 	_global_scale_prop_set, ["scaleY"]);
			Tweener.registerSpecialPropertySplitter("_global_scale", _global_scale_splitter);
		
			//Tweener.registerSpecialProperty("_left"					, _left_prop_get,			_left_prop_set, []);
			//Tweener.registerSpecialProperty("_right"					, );
			//Tweener.registerSpecialProperty("_top"   					, );
			//Tweener.registerSpecialProperty("_bottom"					, );
		
			//Tweener.registerSpecialPropertySplitter("_global_bounds_top", _global_bounds_splitter);
		
			/*
				_bounds_top { }
				_bounds_bottom { }
				_bounds_left { }
				_bounds_right { }
				
				_global_bounds_top
				_global_bounds_bottom
				_global_bounds_left
				_global_bounds_right
			*/
		}
		
		/*
		-----------------------------------------------------------------------------------------------------
			Normal Matrix Getter / Setter / Splitter
		-----------------------------------------------------------------------------------------------------
		*/
		
		protected static function _matrix_prop_get(p_obj:Object, p_parameters:Array, p_extra:Object = null):Number
		{
			return p_obj.transform.matrix[p_parameters[0]]
		}
		
		protected static function _matrix_prop_set(p_obj:Object, p_value:Number, p_parameters:Array, p_extra:Object = null):void
		{
			var mat:Matrix = p_obj.transform.matrix;
			mat[p_parameters[0]] = p_value;
			p_obj.transform.matrix = mat;
		}
		
		protected static function _matrix_splitter(p_value:Object, p_parameters:Array):Array
		{	
			var nArray:Array = new Array();
			if (p_value == null) {
				nArray.push({name:"_matrix_a",		value:1});
				nArray.push({name:"_matrix_b",		value:0});
				nArray.push({name:"_matrix_c",		value:0});
				nArray.push({name:"_matrix_d",		value:1});
				nArray.push({name:"_matrix_tx",	value:0});
				nArray.push({name:"_matrix_ty",	value:0});
			} else {
				nArray.push({name:"_matrix_a",		value:Matrix(p_value).a});
				nArray.push({name:"_matrix_b",		value:Matrix(p_value).b});
				nArray.push({name:"_matrix_c",		value:Matrix(p_value).c});
				nArray.push({name:"_matrix_d",		value:Matrix(p_value).d});
				nArray.push({name:"_matrix_tx",	value:Matrix(p_value).tx});
				nArray.push({name:"_matrix_ty",	value:Matrix(p_value).ty});
			}
			return nArray;
		}
		
		/*
		-----------------------------------------------------------------------------------------
			Global Coordinate Matrix Control Getter / Setter / Splitter
		-----------------------------------------------------------------------------------------
		*/
		
		protected static function _global_matrix_prop_get(p_obj:Object, p_parameters:Array, p_extra:Object = null):Number
		{
			return p_obj.transform.concatenatedMatrix[p_parameters[0]]
		}
		
		protected static function _global_matrix_prop_set(p_obj:Object, p_value:Number, p_parameters:Array, p_extra:Object = null):void
		{
			var cmat:Matrix = p_obj.transform.concatenatedMatrix;
			var pcmat:Matrix = p_obj.parent.transform.concatenatedMatrix;
			pcmat.invert();
			
			cmat[p_parameters[0]] = p_value;
			cmat.concat(pcmat);
			
			p_obj.transform.matrix = cmat;
		}
		
		protected static function _global_matrix_splitter(p_value:Object, p_parameters:Array):Array
		{
			var nArray:Array = new Array();
			if (p_value == null) {
				nArray.push({name:"_global_matrix_a",		value:1});
				nArray.push({name:"_global_matrix_b",		value:0});
				nArray.push({name:"_global_matrix_c",		value:0});
				nArray.push({name:"_global_matrix_d",		value:1});
				nArray.push({name:"_global_matrix_tx",	value:0});
				nArray.push({name:"_global_matrix_ty",	value:0});
			} else {
				nArray.push({name:"_global_matrix_a",		value:Matrix(p_value).a});
				nArray.push({name:"_global_matrix_b",		value:Matrix(p_value).b});
				nArray.push({name:"_global_matrix_c",		value:Matrix(p_value).c});
				nArray.push({name:"_global_matrix_d",		value:Matrix(p_value).d});
				nArray.push({name:"_global_matrix_tx",	value:Matrix(p_value).tx});
				nArray.push({name:"_global_matrix_ty",	value:Matrix(p_value).ty});
			}
			return nArray;
		}
		
		
		/*
		-----------------------------------------------------------------------------------------
			Global Coordinate Control Getter / Setter / Splitter
		-----------------------------------------------------------------------------------------
		*/
		
		protected static function _global_xy_prop_get(p_obj:Object, p_parameters:Array, p_extra:Object = null):Number
		{
			var pt:Point = new Point(p_obj.x, p_obj.y);
			pt = DisplayObject(p_obj).parent.localToGlobal(pt);
			return pt[p_parameters[0]];
		}
		
		protected static function _global_xy_prop_set(p_obj:Object, p_value:Number, p_parameters:Array, p_extra:Object = null):void
		{
			var dobj:DisplayObject = DisplayObject(p_obj);
			var pt:Point = new Point(dobj.x, dobj.y);
			
			pt = dobj.parent.localToGlobal(pt);
			pt[p_parameters[0]] = p_value;
			pt = dobj.parent.globalToLocal(pt);
			
			dobj.x = pt.x;
			dobj.y = pt.y;
		}
		
		
		
		protected static function _global_rotation_prop_get(p_obj:Object, p_parameters:Array, p_extra:Object = null):Number
		{
			var rot:Number = 0;
			var dobj:DisplayObject = DisplayObject(p_obj);
			while(dobj){
				rot += dobj.rotation;
				dobj = dobj.parent;
			}
			
			return rot;
		}
		
		protected static function _global_rotation_prop_set(p_obj:Object, p_value:Number, p_parameters:Array, p_extra:Object = null):void
		{
			var rot:Number = p_value;
			var dobj:DisplayObject = DisplayObject(p_obj).parent;
			while(dobj.parent)
			{
				rot -= dobj.rotation;
				dobj = dobj.parent;
			}
			
			dobj.rotation = rot;
		}
		
		
		
		protected static function _global_scale_prop_get(p_obj:Object, p_parameters:Array, p_extra:Object = null):Number
		{
			var scl:Number = 0;
			var dobj:Object = p_obj;
			while(dobj){
				scl *= dobj[p_parameters[0]];
				dobj = dobj.parent;
			}
			
			return scl;
		}
		
		protected static function _global_scale_prop_set(p_obj:Object, p_value:Number, p_parameters:Array, p_extra:Object = null):void
		{
			var scl:Number = p_value;
			var dobj:DisplayObject = DisplayObject(p_obj).parent;
			while(dobj.parent)
			{
				scl /= dobj[p_parameters[0]];
				dobj = dobj.parent;
			}
			
			dobj[p_parameters[0]] = scl;
		}
		
		
		protected static function _global_scale_splitter(p_value:Object, p_parameters:Array):Array
		{
			var nArray:Array = new Array();
			if (p_value == null) {
				nArray.push({name:"_global_scaleX",	value:1});
				nArray.push({name:"_global_scaleY",	value:1});
			} else {
				nArray.push({name:"_global_scaleX",	value:p_value});
				nArray.push({name:"_global_scaleY",	value:p_value});
			}
			return nArray;
		}
		
		/*
		---------------------------------------------------------------------------------
		---------------------------------------------------------------------------------
		*/
		/*
		protected static function _left_prop_get(p_obj:Object, p_parameters:Array, p_extra:Object = null):Number
		{
			
		}*/
	}
}