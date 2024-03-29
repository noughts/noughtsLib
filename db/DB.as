﻿package jp.noughts.db{
	import flash.data.SQLConnection;
	import flash.data.SQLSchemaResult;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;import org.osflash.signals.natives.base.*;

	import jp.noughts.progression.commands.db.*;

	public class DB	{

		protected static var schemas:Dictionary = new Dictionary();
		protected static var aliases:Object = {};
		protected static var cache:Object = {};

		/**
		 * Returns a connection by the registered alias and with the appropriate synchronisation. This provides
		 * a cache for the connection objects to be used. The main.db database is preregistered under the alias
		 * "main", so a call to getConnection with no parameters will return the default application database.
		 */
		public static function getConnection(alias:String = "main", isSync:Boolean = false):SQLConnection{
			var key:String = alias + " - " + (isSync ? "sync" : "async");

			if (key in cache){
				return cache[key];
			}

			if ( !(alias in aliases)){
				return null;
			}

			var file:File = aliases[alias] is File ? aliases[alias] as File : File.documentsDirectory.resolvePath(aliases[alias]);
			var conn:SQLConnection = new SQLConnection();
			if (isSync){
				conn.open(file);
			} else {
				conn.openAsync(file);
			}

			cache[key] = conn;
			return conn;
		}


		public static function getConnectionCommand( alias:String="main" ):SerialList{
			var key:String = alias + " - async";

			if (key in cache){
				return cache[key];
			}

			if ( !(alias in aliases)){
				return null;
			}

			var file:File = aliases[alias] is File ? aliases[alias] as File : File.documentsDirectory.resolvePath(aliases[alias]);
			var conn:SQLConnection = new SQLConnection();


			var slist:SerialList = new SerialList();
			slist.addCommand(
				"DB.getConnection 開始...",
				new OpenConnection( conn, file ),
				function(){
					cache[key] = conn;
					slist.latestData = conn;
				},
				"DB.getConnection 終了",
			null);
			return slist;
		}

		/**
		 * Registers a database file with an alias for the database. This allows connection objects
		 * to be created, retrieved, and cached by the getConnection method.
		 */
		public static function registerConnectionAlias(fileNameOrObject:Object, alias:String):void{
			aliases[alias] = fileNameOrObject is File ? fileNameOrObject.nativePath : fileNameOrObject;
		}

		// this private method pre-registers the main database to the system
		private static var init:* = function():void {
			registerConnectionAlias("main.db", "main");
		}();

		/**
		 * Returns and caches the schema for a connection to a database
		 */
		public static function getSchema(conn:SQLConnection):void{
			getSchemaCommand(conn).execute();				
		}

		// SQLSchemaResult を返す
		public static function getSchemaCommand( conn:SQLConnection ):SerialList{
			var slist:SerialList = new SerialList();
			if ( !(conn in schemas)){
				slist.addCommand(
					new LoadSchema( conn ),
					function(){
						schemas[conn] = conn.getSchemaResult();
					},
				null);
			}
			slist.addCommand(
				function(){
					slist.latestData = schemas[conn]
				},
			null);
			return slist;			
		}

		/**
		 * Forces a refresh of a schema, used when a table update has been made or tables have been added
		 */
		//public static function refreshSchema(conn:SQLConnection):SQLSchemaResult{
		//	delete schemas[conn];
		//	return getSchema(conn);
		//}

		// SQLSchemaResult を返す
		public static function refreshSchemaCommand(conn:SQLConnection):SerialList{
			delete schemas[conn];

			var slist:SerialList = new SerialList();
			slist.addCommand(
				getSchemaCommand( conn ),
				function(){
					slist.latestData = this.latestData;
				},
			null);
			return slist;
		}

	}
}





