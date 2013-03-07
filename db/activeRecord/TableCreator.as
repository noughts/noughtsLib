package jp.noughts.db.activeRecord
{
	import flash.data.SQLColumnSchema;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;

	import jp.noughts.db.DB;
	import jp.noughts.db.sql_db;
	import jp.noughts.db.utils.Reflection;

	import jp.noughts.progression.commands.db.*;
	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;


	use namespace sql_db;


	public class TableCreator{
		private static var tablesUpdated:Object = {};


		/**
		 * Creates a new table for this object if one does not already exist. In addition, will
		 * add new fields to existing tables if an object has changed
		 */
		public static function updateTableCommand(obj:ActiveRecord, schema:SQLTableSchema = null):SerialList{
			var tableName:String = ActiveRecord.schemaTranslation.getTable(obj.className);
			var primaryKey:String = ActiveRecord.schemaTranslation.getPrimaryKey(obj.className);

			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = obj.connection;
			var sql:String;

			// get all this object's properties we want to store in the database
			var def:XML = Reflection.describe(obj);
			var publicVars:XMLList = def.*.(
					(
						localName() == "variable" ||
						(localName() == "accessor" && @access == "readwrite")
					)
					&&
					(
						@type == "String" ||
						@type == "Number" ||
						@type == "Boolean" ||
						@type == "uint" ||
						@type == "int" ||
						@type == "Date" ||
						@type == "flash.utils::ByteArray"
					)
				);
			//trace( publicVars )
			var field:XML;
			var fieldDef:Array

			var slist:SerialList = new SerialList();
			slist.addCommand( "updateTable 開始" )
			if (!schema){
				var dbschema:SQLSchemaResult

				slist.addCommand(
					DB.getSchemaCommand( obj.connection ),
					function(){
						dbschema = this.latestData;
						// first, find the table this object represents
						if (dbschema){
							for each (var tmpTable:SQLTableSchema in dbschema.tables){
								if (tmpTable.name == tableName){
									schema = tmpTable;
									break;
								}
							}
						}
						trace("begin前チェック", obj.connection.inTransaction)
						var slist2:SerialList = new SerialList();
						slist2.addCommand( new BeginTransaction(obj.connection) );

						// if no table was found, create it, otherwise, update any missing fields
						if (!schema){
							var fields:Array = [];

							for each (field in publicVars){
								fieldDef = [field.@name, dbTypes[field.@type]];

								if (field.@name == primaryKey){
									fieldDef.push("PRIMARY KEY AUTOINCREMENT");
								}
								fields.push(fieldDef.join(" "));
							}

							sql = "CREATE TABLE " + tableName + " (" + fields.join(", ") + ")";
							stmt.text = sql;
							slist2.addCommand( new ExecuteStatement( stmt ) );
						} else {
							// check if any fields differ or have been added
							for each (field in publicVars){
								var found:Boolean = false;
								for each (var column:SQLColumnSchema in schema.columns){
									if (column.name == field.@name){
										found = true;
										break;
									}
								}

								if (found)
									continue;

								// add the field to be created
								fieldDef = ["ADD", field.@name, dbTypes[field.@type]];

								sql = "ALTER TABLE " + tableName + " " + fieldDef.join(" ");
								stmt.text = sql;
								slist2.addCommand( new ExecuteStatement( stmt ) );
							}
						}
						slist.insertCommand( slist2 )
					},
					1,
					function(){
						trace("コミット前チェック", obj.connection.inTransaction)
						if (obj.connection.inTransaction){
							obj.connection.commit();
						}
					},
					"updateTable終了",
				null);
			}
			return slist
		}

		sql_db static var dbTypes:Object = {
			"String": "VARCHAR",
			"Number": "DOUBLE",
			"Boolean": "BOOLEAN",
			"uint": "INTEGER",
			"int": "INTEGER",
			"Date": "DATETIME",
			"flash.utils::ByteArray": "BLOB"
		};
	}
}
