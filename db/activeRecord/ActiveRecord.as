package jp.noughts.db.activeRecord
{
	import jp.progression.config.*;import jp.progression.debug.*;import jp.progression.casts.*;import jp.progression.commands.display.*;import jp.progression.commands.lists.*;import jp.progression.commands.managers.*;import jp.progression.commands.media.*;import jp.progression.commands.net.*;import jp.progression.commands.tweens.*;import jp.progression.commands.*;import jp.progression.data.*;import jp.progression.events.*;import jp.progression.loader.*;import jp.progression.*;import jp.progression.scenes.*;import jp.nium.core.debug.Logger;import caurina.transitions.*;import caurina.transitions.properties.*;

	import flash.data.*;
	import flash.events.*
	import flash.utils.*;
	import jp.nium.core.debug.Logger;

	import mx.utils.*;

	import jp.noughts.db.DB;
	import jp.noughts.db.sql_db;
	import jp.noughts.db.utils.Inflector;
	import jp.noughts.db.utils.Reflection;
	import org.osflash.signals.*;import org.osflash.signals.natives.*;import org.osflash.signals.natives.sets.*;import org.osflash.signals.natives.base.*;

	import jp.noughts.progression.commands.db.*;

	use namespace sql_db;
	use namespace flash_proxy;

	public class ActiveRecord extends Proxy implements IEventDispatcher	{
		sql_db static var tableSchemaCache:Object = {};
		sql_db static var columnSchemaCache:Object = {};

		public var queryComplete_sig:Signal = new Signal( Object )
		public var saveComplete_sig:Signal = new Signal( Boolean )
		public var countComplete_sig:Signal = new Signal( uint )
		//public var saveAllComplete_sig:Signal = new Signal()

		/**
		 * Stores the runtime properties of related objects and arrays
		 */
		protected var relatedData:Object = {};

		/**
		 * The default SQLConnection alias used for this stored object
		 */
		public static var defaultConnectionAlias:String = "main";

		/**
		 * The default object that can translate class names, properties, and keys for the database
		 */
		public static var schemaTranslation:SchemaTranslation = new SchemaTranslation();

		/**
		 * Stores the constructor of this class since it is not available to Proxied objects
		 */
		public var constructor:Object;

		/**
		 * This object's SQLConnection object, retrieved upon instantiation
		 */
		static public function hoge(){
		}


		static public var defaultConnection:SQLConnection;
		public var connection:SQLConnection;

		private var _className:String;
		private var eventDispatcher:EventDispatcher;

		[Bindable]
		public var id:uint;


		public function ActiveRecord(){
			constructor = getDefinitionByName(getQualifiedClassName(this));
			eventDispatcher = new EventDispatcher(this);
			if( defaultConnection ){
				connection = defaultConnection
			} else {
				connection = DB.getConnection( defaultConnectionAlias );
			}
		}



		// インデックスを作成する
		// 例: GroupModel.model().createIndex( ["remote_id"] )
		public function createIndex( columnNames_array:Array ):void{
			var tableName:String = schemaTranslation.getTable(className);
			var indexName:String = "idx_"+ tableName +"_"+ columnNames_array.join("_");
			var columnNames_str:String = columnNames_array.join(",")
			//query( "CREATE INDEX IF NOT EXISTS "+ indexName +" ON "+ tableName +" ("+ columnNames_str +")" )

			var sql:String = "CREATE INDEX IF NOT EXISTS "+ indexName +" ON "+ tableName +" ("+ columnNames_str +")"
			queryCommand( sql ).execute();
		}

		/**
		 * Loads the object from the database by the id passed
		 *
		 * @param The database id or primary key value
		 * @return Whether the object was successfully loaded
		 */
		public function load(id:uint):void{
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			var stmt:SQLStatement = new SQLStatement();

			var sql:String = "SELECT * FROM " + tableName + " WHERE " + primaryKey + " = ?"

			var slist:SerialList = new SerialList();
			slist.addCommand(
				queryCommand( sql, id ),
				function(){
					var result:Array = this.latestData;
					setDBProperties(result[0]);
				},
			null);
			slist.execute();
			

			//var result:Array = query( sql, id ) as Array;
			//if (!result.length)
			//	return false;

			//setDBProperties(result[0]);
			//return true;
		}

		/**
		 * Loads the object from the database by the conditions passed
		 *
		 * @param Conditions to be passed
		 * @param The parameter replacements to replace the ?s
		 * @return Whether the object was succesfully loaded
		 */
		public function loadBy(conditions:String, ...parameters:Array):void{
			var tableName:String = schemaTranslation.getTable(className);
			var sql:String = "SELECT * FROM " + tableName + " WHERE " + conditions;

			var slist:SerialList = new SerialList();
			slist.addCommand(
				queryCommand( sql, parameters ),
				function(){
					var result:Array = this.latestData as Array;
					if( !result.length ){
						return;
					}
					setDBProperties(result[0]);
				},
			null);
			slist.execute();
		}


		public function saveAllCommand( data_vec:* ):SerialList{
			var self = this;

			// set up the variables to save this object to the database
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);

			var data:Object

			var slist:SerialList = new SerialList();
			slist.addCommand(
				new BeginTransaction( connection ),
				getDBPropertiesCommand(),
				function(){
					data = this.latestData;

					delete data[primaryKey];
					var fields:Array = [];
					for (var fieldName:String in data){
						fields.push(fieldName);
					}
					var fieldsLength:uint = fields.length;
					var fieldsJoined:String = fields.join(", ")

					var slist2:SerialList = new SerialList();

					var len:uint = data_vec.length
					for( var i:int=0; i<len; i++ ){
						slist2.addCommand(
							new Var( "i", i ),
							function(){
								Logger.info( "statement execute" )
								var i:uint = this.getVar( "i" )

								var stmt:SQLStatement = new SQLStatement()
								stmt.sqlConnection = connection;
								var sql:String = "INSERT INTO " + tableName + " (" + fieldsJoined + ") VALUES (?";
								for( var j:uint=0; j < fieldsLength-1; j++ ){
									sql += ", ?";
								}
								sql += ")";
								stmt.text = sql;

								var counter:uint = 0
								for (var fieldName:String in data){
									stmt.parameters[counter] = data[fieldName];
									counter++;
								}
								slist2.insertCommand( new ExecuteStatement( stmt ) );
							},

						null);
					}
					slist.insertCommand( slist2 )
				},
				new CommitTransaction( connection ),
			null);
			return slist;
		}



		/**
		 * Saves the object to the database.
		 *
		 * @return Whether the object successfully saved
		 */
		public function saveCommand():SerialList{
			// dispatch the saving event and allow for the save to be canceled
			var savingEvent:ActiveRecordEvent = new ActiveRecordEvent(ActiveRecordEvent.SAVING, true);
			dispatchEvent(savingEvent);

			if (savingEvent.isDefaultPrevented())
				return null;

			// add timestamps if certain "created" and/or "modified" fields are defined
			if (!id && hasOwnProperty(schemaTranslation.getCreatedField()))
				this[schemaTranslation.getCreatedField()] = new Date();

			if (hasOwnProperty(schemaTranslation.getModifiedField()))
				this[schemaTranslation.getModifiedField()] = new Date();

			// set up the variables to save this object to the database
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			var parameters:Array = [];
			var sql:String;

			var data:Object


			var slist:SerialList = new SerialList();
			slist.addCommand(
				getDBPropertiesCommand(),
				function(){
					data = this.latestData;

					delete data[primaryKey];
					var fields:Array = [];
					for (var fieldName:String in data){
						fields.push(fieldName);
						parameters.push(data[fieldName]);
					}

					if (id) {
						// this is an update statement
						sql = "UPDATE " + tableName + " SET " + fields.join(" = ?, ") + " = ? WHERE " + primaryKey + " = ?";
						parameters.push(id);
					} else {
						sql = "INSERT INTO " + tableName + " (" + fields.join(", ") + ") VALUES (?";
						for (var j:uint = 0; j < fields.length - 1; j++)
							sql += ", ?";
						sql += ")";
					}

					slist.insertCommand( queryCommand( sql, parameters ) )
				},
				function(){
					var result:Object = this.latestData;
					if( !result ){
						slist.latestData = null;
						return;
					}
					if( !id ){
						id = connection.lastInsertRowID;
					}
					slist.latestData = result;
				},
			null);
			return slist;
		}

		//////////// These are ideally static methods that would work with a subclass, however, since we
		//////////// cannot get the class of the item calling these methods statically we must make
		//////////// them not static.

		 /**
		 * Return object found based on id
		 *
		 * @param The id of the object in the database
		 */
		public function find(id:uint):ActiveRecord
		{
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			var result:Array = findAll(primaryKey + " = ?", [id]);
			return result ? result[0] : null;
		}

		/**
		 * Returns first object found based on parameters
		 */
		 public function findFirst(conditions:String = null, conditionParams:Array = null, order:String = null):ActiveRecord
		 {
		 	var result:Array = findAll(conditions, conditionParams, order, 1);
			return result ? result[0] : null;
		 }

		/**
		 * Returns array of objects based on parameters
		 */
		public function findAll(conditions:String = null, conditionParams:Array = null, order:String = null, limit:uint = 0, offset:uint = 0, joins:String = null):Array
		{
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);

			var sql:String = "SELECT *, " + tableName + "." + primaryKey + " FROM " + tableName;
			sql += assembleQuery(conditions, order, limit, offset, joins);

			var items:Array = loadItems(constructor as Class, sql, conditionParams);
			return (items == null ? [] : items);
		}

		/**
		 * Returns array of objects based on the full sql statement
		 */
		public function findBySQL(sql:String, ...params:Array):Array
		{
			return loadItems(constructor as Class, sql, params);
		}

		/**
		 * Returns whether or not the object exists in the database
		 */
		public function exists(id:uint):Boolean
		{
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			return (count(primaryKey + " = ?", [id]) > 0);
		}

		/**
		 * Creates new object, populates the attributes from the array,
		 * saves it if it validates, and returns it
		 */
		// ActiveRecord を返します
		public function createCommand(properties:Object = null):SerialList{
			var obj:ActiveRecord = new constructor();
			obj.setDBProperties(properties);

			var slist:SerialList = new SerialList();
			slist.addCommand(
				obj.saveCommand(),
				function(){
					slist.latestData = obj;
				},
			null);
			return slist;
		}

		/**
		 * Updates an object already stored in the database with the properties passed
		 * @return Whether it was successfully updated
		 */
		public function update(id:uint, updates:String, updateParams:Array = null):void{
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);

			if (!updateParams)
				updateParams = [id];
			else
				updateParams.push(id);

			var sql:String = "UPDATE " + tableName + " SET " + updates + " WHERE " + primaryKey + " = ?"

			queryCommand( sql, updateParams ).execute();
		}

		/**
		 * Updates all records' properties matching conditions
		 * @return Number of successful updates
		 */
		public function updateAll(conditions:String = null, conditionParams:Array = null, updates:String = null, updateParams:Array = null):void{
			var tableName:String = schemaTranslation.getTable(className);

			var params:Array = conditionParams ?
					(
						updateParams ? conditionParams.concat(updateParams) : conditionParams
					)
				: updateParams;

			var sql:String = "UPDATE " + tableName + " SET " + updates
			queryCommand( sql, params ).execute();
		}

		/**
		 * Delete object by id
		 *
		 * @param The id of the object in the database
		 * @return Whether object was deleted
		 */
		public function deleteById(id:uint):void{
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			queryCommand( "DELETE FROM " + tableName + " WHERE " + primaryKey + " = ?", id ).execute();
		}

		/**
		 * Deletes all records by conditions
		 *
		 * @return Number of successful deletes
		 */
		public function deleteAllCommand(conditions:String = null, conditionParams:Array = null):SerialList{
			var tableName:String = schemaTranslation.getTable(className);

			var sql:String = "DELETE FROM " + tableName;
			sql += assembleQuery(conditions);
			return queryCommand( sql, conditionParams );
		}

		/**
		 * Returns the number of records that meet the conditions
		 */
		public function count(conditions:String = null, conditionParams:Array = null, joins:String = null):void{
			var tableName:String = schemaTranslation.getTable(className);
			var sql:String = "SELECT COUNT(*) FROM " + tableName;
			sql += assembleQuery(conditions, null, 0, 0, joins);

			var slist:SerialList = new SerialList();
			slist.addCommand(
				queryCommand( sql, conditionParams ),
				function(){
					var result:Array = this.latestData as Array;
					countComplete_sig.dispatch( result ? result[0][0] : 0 );
				},
			null);
			slist.execute();
		}

		/**
		 * Returns the number of records returned by the sql statement
		 */
		public function countBySql( sql:String, params:Array = null ):void{
			var slist:SerialList = new SerialList();
			slist.addCommand(
				queryCommand( sql, params ),
				function(){
					var result:Array = this.latestData as Array;
					countComplete_sig.dispatch( result ? result[0][0] : 0 );
				},
			null);
			slist.execute();
		}

		/**
		 * Increment a property in the database
		 *
		 * @param The id of the class to be incremented
		 * @param The property of the class to be incremented
		 */
		public function incrementCounter(id:uint, counter:String):void
		{
			update(id, counter + " = " + counter + " + 1");
		}

		/**
		 * Decrements a counter in a record
		 *
		 * @param The id of the class to be incremented
		 * @param The property of the class to be decremented
		 */
		public function decrementCounter(id:uint, counter:String):void
		{
			update(id, counter + " = " + counter + " - 1");
		}


		flash_proxy override function getProperty(name:*):*
		{
			var property:String = name.toString();

			var relation:XML = Reflection.getMetadata(this, "RelatedTo").arg.(@key == "name" && @value == property).parent();

			if (!relation || property in relatedData)
				return relatedData[property];

			var type:Class = getDefinitionByName(relation.arg.(@key == "className").@value) as Class;
			var multiple:Boolean = relation.arg.(@key == "" && @value == "multiple").length();
			relatedData[property] = loadRelated(type, multiple);
			return relatedData[property];
		}

		flash_proxy override function hasProperty(name:*):Boolean
		{
			name = name.toString();

			var relation:XML = Reflection.getMetadata(this, "RelatedTo").arg.(@key == "name" && @value == name).parent();

			return relation != null;
		}


		flash_proxy override function callProperty(name:*, ...params:Array):*
		{
			var matches:Array = name.toString().match(/^([a-z]+)(.+)/);
			var prop:QName = new QName(sql_db, matches[1] + "Related");
			if (!matches || !(this[prop] is Function) )
				return;

			var relationalMethod:Function = this[prop];
			var propertyName:String = Inflector.lowerFirst(matches[2]);
			var relation:XML = Reflection.getMetadata(this, "RelatedTo").arg.(@key == "name" && @value == propertyName).parent();

			if (!relation)
				return;

			var type:Class = getDefinitionByName(relation.arg.(@key == "className").@value) as Class;
			var multiple:Boolean = relation.arg.(@key == "" && @value == "multiple").length();

			if (relationalMethod == saveRelated)
				params.unshift(this[propertyName]);
			params.unshift(multiple);
			params.unshift(type);

			if (relationalMethod == loadRelated)
				return relatedData[name] = relationalMethod.apply(this, params);
			else
				return relationalMethod.apply(this, params);
		}


		sql_db function loadRelated(clazz:Class, multiple:Boolean = false, conditions:String = null, conditionParams:Array = null, order:String = null, limit:uint = 0, offset:uint = 0):Object{
			var r:RelationalOperation = new RelationalOperation(this, clazz, multiple);
			return r.loadRelated(conditions, conditionParams, order, limit, offset);
		}

		//sql_db function countRelated(clazz:Class, multiple:Boolean = false, conditions:String = null, conditionParams:Array = null):uint{
		//	var r:RelationalOperation = new RelationalOperation(this, clazz, multiple);
		//	return r.countRelated(conditions, conditionParams);
		//}

		sql_db function saveRelated(clazz:Class, multiple:Boolean = false, property:Object = null):Boolean{
			var r:RelationalOperation = new RelationalOperation(this, clazz, multiple);
			return r.saveRelated(property);
		}

		//sql_db function deleteRelated(clazz:Class, multiple:Boolean = false, conditions:String = null, conditionParams:Array = null, joinOnly:Boolean = true):uint{
		//	var r:RelationalOperation = new RelationalOperation(this, clazz, multiple);
		//	return r.deleteRelated(conditions, conditionParams, joinOnly);
		//}


		/**
		 * Gives the class name for this object without the package info
		 */
		sql_db function get className():String{
			if (!_className){
				var classParts:Array = getQualifiedClassName(this).split("::");
				_className = (classParts.length == 1 ? classParts[0] : classParts[1]);
			}
			return _className;
		}



		public function query(sql:String, ...params:Array):void{
		}

		// latestData の型は Object
		public function queryCommand( sql:String, ...params:Array ):SerialList{
			var stmt:SQLStatement = new SQLStatement();

			stmt.sqlConnection = connection;
			stmt.text = sql;

			var paramsFound:Boolean = false
			if( params.length == 1 && params[0]!=null ){
				if( params[0] is Array ){	
					params = params[0];
				}
				paramsFound = true;
			}

			if( paramsFound ){
				for (var i:int = 0; i < params.length; i++){
					stmt.parameters[i] = params[i];
				}
			}
			//trace( "params", ObjectUtil.toString(params) )
			//trace( "stmt", ObjectUtil.toString(stmt.parameters) )

			var slist:SerialList = new SerialList();
			slist.addCommand(
				new ExecuteStatement( stmt ),
				function(){
					var result:SQLResult = this.latestData;
					var out:Object = sql.toUpperCase().indexOf("SELECT ") == 0 ? result.data || [] : result.rowsAffected;
					slist.latestData = out;
				},
			null);
			return slist;
		}




		private var sqlConnectionOpened_sig:NativeSignal
		public function asyncQuery( clazz:Class, sql:String, resultFunction:Function, ...params:Array ):void{
			var stmt:SQLStatement = new SQLStatement();
			stmt.text = sql;
			stmt.itemClass = clazz;

			stmt.sqlConnection = DB.getConnection(defaultConnectionAlias);
			sqlConnectionOpened_sig = new NativeSignal( stmt.sqlConnection, SQLEvent.OPEN, SQLEvent )
			sqlConnectionOpened_sig.addOnce( function(e:SQLEvent):void{
				//Logger.info( "ActiveRecord asyncQuery connection opened" )
				if (params.length == 1 && params[0] is Array)
					params = params[0];

				for (var i:int = 0; i < params.length; i++)
					stmt.parameters[i] = params[i];

				var listener:Function = function(event:SQLEvent):void
				{
					var result:SQLResult = stmt.getResult();
					resultFunction(sql.toUpperCase().indexOf("SELECT ") == 0 ? result.data || [] : result.rowsAffected);
					stmt.removeEventListener(SQLEvent.RESULT, listener);
				};
				stmt.addEventListener(SQLEvent.RESULT, listener);
				stmt.execute();
			} )
			// 2回目以降は接続済みになるので、openedをdispatchする
			if( stmt.sqlConnection.connected ){
				sqlConnectionOpened_sig.dispatch( new SQLEvent(SQLEvent.OPEN) )
			}
		}


		sql_db function loadItems(clazz:Class, sql:String, ...params:Array):Array{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = connection;
			stmt.text = sql;
			stmt.itemClass = clazz;

			if (params.length == 1 && params[0] is Array){
				params = params[0];
			}

			for (var i:int = 0; i < params.length; i++){
				if( params[i] ){
					stmt.parameters[i] = params[i];
				}
			}

			stmt.execute();
			var result:SQLResult = stmt.getResult();

			return result ? result.data : null;
		}

		sql_db function assembleQuery(conditions:String = null, order:String = null, limit:uint = 0, offset:uint = 0, joins:String = null):String{
			var sql:String = "";

			if (joins){
				sql += joins;
			}

			if (conditions){
				sql += " WHERE " + conditions;
			}

			if (order){
				sql += " ORDER BY " + order;
			}

			if (limit){
				sql += " LIMIT " + limit;
				if (offset){
					sql += " OFFSET " + offset;
				}
			}

			return sql;
		}

		sql_db function setDBProperties(data:Object):void
		{
			var columns:Array = getSchema().columns;

			for each (var column:SQLColumnSchema in columns)
			{
				if (column.primaryKey)
				{
					if (column.name in data)
						id = data[column.name];
				}
				else if (column.name in data)
				{
					this[column.name] = data[column.name];
				}
			}
		}

		//sql_db function getDBProperties():Object{
		//	var tableName:String = schemaTranslation.getTable(className);
		//	var columns:Array = getSchema().columns;

		//	var data:Object = {};

		//	for each (var column:SQLColumnSchema in columns){
		//		if (column.primaryKey){
		//			data[column.name] = id;
		//		} else if (column.name in this){
		//			data[column.name] = this[column.name];
		//		}
		//	}
		//	return data;
		//}

		// Objectを返す
		sql_db function getDBPropertiesCommand():SerialList{
			var tableName:String = schemaTranslation.getTable(className);
			var columns:Array

			var slist:SerialList = new SerialList();
			slist.addCommand(
				getSchemaCommand(),
				function(){
					var schema:SQLTableSchema = this.latestData;
					columns = schema.columns;

					var data:Object = {};
					for each (var column:SQLColumnSchema in columns){
						if (column.primaryKey){
							data[column.name] = id;
						} else if (column.name in this){
							data[column.name] = this[column.name];
						}
					}
					slist.latestData = data;
				},
			null);
			return slist
		}


		/**
		 * Creates a new table for this object if one does not already exist. In addition, will
		 * add new fields to existing tables if an object has changed
		 */
		sql_db function getSchema(tableName:String = null, updateTable:Boolean = false):SQLTableSchema{
			return null;
		}


		// SQLTableSchema を返す
		sql_db function getSchemaCommand( tableName:String = null, updateTable:Boolean = false ):SerialList{
			var self:ActiveRecord = this;
			if (!tableName){
				tableName = schemaTranslation.getTable(className);
			}
			var slist:SerialList = new SerialList();

			if (tableName in tableSchemaCache){
				slist.latestData = tableSchemaCache[tableName];
				return slist;
			}

			var schema:SQLSchemaResult
			var table:SQLTableSchema;

			slist.addCommand(
				DB.getSchemaCommand( connection ),
				function(){
					schema = this.latestData;

					// first, find the table this object represents
					//trace( "schema.tables", schema.tables )
					if( schema ){
						for each( var tmpTable:SQLTableSchema in schema.tables ){
							if (tmpTable.name == tableName){
								table = tmpTable;
								break;
							}
						}
					}

					if (updateTable){
						slist.insertCommand( TableCreator.updateTableCommand( self, table ) )
					}
				},
				function(){
					var fields:Object;
					if (table && table.columns.length){
						fields = {};
						for each (var column:SQLColumnSchema in table.columns){
							fields[column.name] = column;
						}
					}

					columnSchemaCache[tableName] = fields;
					tableSchemaCache[tableName] = table;
					trace(">>>>>>>>>>>>>>>>>>>>>>>", table)
					slist.latestData = table;
				},
			null);
			return slist;
		}






		sql_db function getFields(tableName:String = null):Object
		{
			if (!tableName)
				tableName = schemaTranslation.getTable(className);

			if (!(tableName in columnSchemaCache))
				getSchema(tableName);

			return columnSchemaCache[tableName];
		}


		/** EVENT DISPATCHER STUFF **/

		public function hasEventListener(type:String):Boolean
		{
			return eventDispatcher.hasEventListener(type);
		}

		public function willTrigger(type:String):Boolean
		{
			return eventDispatcher.willTrigger(type);
		}

		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0.0, useWeakReference:Boolean=false):void
		{
			eventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}

		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			eventDispatcher.removeEventListener(type, listener, useCapture);
		}

		public function dispatchEvent(event:Event):Boolean
		{
			return eventDispatcher.dispatchEvent(event);
		}

		public function toString():String
		{
			return "[" + className + "(id=" + id + ")]";
		}
	}
}