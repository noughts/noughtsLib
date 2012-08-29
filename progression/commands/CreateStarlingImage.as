/**
 * Progression 4
 * 
 * @author Copyright (C) 2007-2010 taka:nium.jp, All Rights Reserved.
 * @version 4.0.22
 * @see http://progression.jp/
 * 
 * Progression Libraries is dual licensed under the "Progression Library License" and "GPL".
 * http://progression.jp/license
 */
package jp.noughts.progression.commands {
	import jp.progression.commands.*;
	import jp.progression.commands.lists.*;
	import jp.nium.utils.ObjectUtil;
	import org.osflash.signals.*;
	import jp.nium.core.debug.Logger;

	import starling.core.Starling;
	import starling.display.Image;
	import starling.textures.Texture;

	import flash.display.*;
	import flash.events.*;

	import jp.noughts.display.*;


	/**
	 * <span lang="ja">Listen クラスは、指定された EventDispatcher が指定されたイベントを送出するまで待機処理を行うコマンドクラスです。</span>
	 * <span lang="en"></span>
	 * 
	 * @example <listing version="3.0">
	 * // SerialList インスタンスを作成する
	 * var com:SerialList = new SerialList();
	 * 
	 * // コマンドを登録する
	 * com.addCommand(
	 * 	new Trace( "クリックを待ちます" ),
	 * 	new CreateStarlingImage( hoge_sig ),
	 * 	new Trace( "クリックされました" )
	 * );
	 * 
	 * // コマンドを実行する
	 * com.execute();
	 * </listing>
	 */
	public class CreateStarlingImage extends Command {
		


		private var _dispatchedArgs:Array;
		public function get dispatchedArgs():Array{ return _dispatchedArgs }

		private var _nativeDisplayObject:DisplayObject;
		private var _starlingImage:Image;

		

		
				

		public function CreateStarlingImage( $nativeDisplayObject:DisplayObject, initObject:Object=null ) {
			// 引数を設定する
			_nativeDisplayObject = $nativeDisplayObject;
			
			// 親クラスを初期化する
			super( _executeFunction, _interruptFunction, initObject );
		}
		
		
		
		
		
		/**
		 * 実行されるコマンドの実装です。
		 */
		private function _executeFunction():void {
			var bd:BitmapData = DrawAuto.drawBmd( _nativeDisplayObject )
			var tex:Texture;

			var slist:SerialList = new SerialList();
			slist.addCommand(
				new WaitFrame( 1 ),
				function(){
					tex = Texture.fromBitmapData( bd, false );
				},
				new WaitFrame( 1 ),
				function(){
					_starlingImage = new Image( tex );
					_onComplete()
				},
			null);
			slist.execute();
		}
		

		private function _onComplete():void{
			super.latestData = _starlingImage;
			super.executeComplete();
		}



		/**
		 * 中断実行されるコマンドの実装です。
		 */
		private function _interruptFunction():void {
		}
		
		/**
		 * <span lang="ja">保持しているデータを解放します。</span>
		 * <span lang="en"></span>
		 */
		override public function dispose():void {
			// 親のメソッドを実行する
			super.dispose();
		}
		
		/**
		 * <span lang="ja">Func インスタンスのコピーを作成して、各プロパティの値を元のプロパティの値と一致するように設定します。</span>
		 * <span lang="en">Duplicates an instance of an Func subclass.</span>
		 * 
		 * @return
		 * <span lang="ja">元のオブジェクトと同じプロパティ値を含む新しい Func インスタンスです。</span>
		 * <span lang="en">A new Func object that is identical to the original.</span>
		 */
		override public function clone():Command {
			return new CreateStarlingImage( _nativeDisplayObject, this );
		}
		
		/**
		 * <span lang="ja">指定されたオブジェクトのストリング表現を返します。</span>
		 * <span lang="en">Returns the string representation of the specified object.</span>
		 * 
		 * @return
		 * <span lang="ja">オブジェクトのストリング表現です。</span>
		 * <span lang="en">A string representation of the object.</span>
		 */
		override public function toString():String {
			return ObjectUtil.formatToString( this, super.className, super.id ? "id" : null, "dispatcher", "eventType" );
		}
		
		
		
		
		

	}
}
