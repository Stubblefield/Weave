/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.services
{
	import avmplus.DescribeType;
	
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.mx_internal;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.services.IWeaveEntityService;
	import weave.api.services.IWeaveGeometryTileService;
	import weave.api.services.beans.Entity;
	import weave.api.services.beans.EntityHierarchyInfo;
	import weave.services.beans.AttributeColumnData;
	import weave.services.beans.GeometryStreamMetadata;
	
	use namespace mx_internal;
	
	/**
	 * This is a wrapper class for making asynchronous calls to a Weave data servlet.
	 * 
	 * @author adufilie
	 */
	public class WeaveDataServlet implements IWeaveEntityService
	{
		protected var servlet:AMF3Servlet;
		private var propertyNameLookup:Dictionary = new Dictionary(); // Function -> String

		public static const DEFAULT_URL:String = '/WeaveServices/DataService';
				
		public function WeaveDataServlet(url:String = null)
		{
			servlet = new AMF3Servlet(url || DEFAULT_URL);
			registerLinkableChild(this, servlet);
			
			var info:* = DescribeType.getInfo(this, DescribeType.METHOD_FLAGS);
			for each (var item:Object in info.traits.methods)
			{
				var func:Function = item.uri ? null : this[item.name] as Function;
				if (func != null)
					propertyNameLookup[func] = item.name;
			}
		}
		
		////////////////////
		// Helper functions
		
		/**
		 * This function will generate a AsyncToken representing a servlet method invocation and add it to the queue.
		 * @param method A WeaveAdminService class member function or a String.
		 * @param parameters Parameters for the servlet method.
		 * @param queued If true, the request will be put into the queue so only one request is made at a time.
		 * @param returnType_or_castFunction
		 *     Either the type of object (Class) returned by the service or a Function that converts an Object to the appropriate type.
		 *     If the service returns an Array of objects, each object in the Array will be cast to this type.
		 *     The object(s) returned by the service will be cast to this type by copying the public properties of the objects.
		 *     It is unnecessary to specify this parameter if the return type is a primitive value.
		 * @return The AsyncToken object representing the servlet method invocation.
		 */		
		private function invoke(method:Object, parameters:Array, returnType_or_castFunction:Object = null):AsyncToken
		{
			var methodName:String;
			if (method is Function)
				methodName = propertyNameLookup[method] as String;
			else
				methodName = method as String;
			
			if (!methodName)
				throw new Error("method must be a member of " + getQualifiedClassName(this));
			
			var token:AsyncToken = servlet.invokeAsyncMethod(methodName, parameters);
			if (returnType_or_castFunction)
			{
				if (!(returnType_or_castFunction is Function || returnType_or_castFunction is Class))
					throw new Error("returnType_or_castFunction parameter must either be a Class or a Function");
				if ([Array, String, Number, int, uint].indexOf(returnType_or_castFunction) < 0)
					addAsyncResponder(token, castResult, null, returnType_or_castFunction);
			}
			return token;
		}
		
		public static function castResult(event:ResultEvent, cast:Object):void
		{
			var results:Array = event.result as Array || [event.result];
			for (var i:int = 0; i < results.length; i++)
			{
				if (cast is Class)
				{
					var result:Object = results[i];
					if (result === null || result is (cast as Class))
						continue;
					var newResult:Object = new cast();
					for (var key:String in result)
						if (newResult.hasOwnProperty(key))
							newResult[key] = result[key];
					results[i] = newResult;
				}
				else
				{
					results[i] = cast(results[i])
				}
			}
			if (event.result != results)
				event.setResult(results[0]);
		}
		
		////////////////////
		// DataEntity info
		
		public function get entityServiceInitialized():Boolean
		{
			return true;
		}
		
		public function getHierarchyInfo(publicMetadata:Object):AsyncToken // returns EntityHierarchyInfo[]
		{
			return invoke(getHierarchyInfo, arguments, EntityHierarchyInfo);
		}
		
		public function getEntities(ids:Array):AsyncToken // returns Entity[]
		{
			return invoke(getEntities, arguments, Entity);
		}
		
		public function findEntityIds(publicMetadata:Object, wildcardFields:Array):AsyncToken // returns int[]
		{
			return invoke(findEntityIds, arguments);
		}
		
		public function findPublicFieldValues(fieldName:String, valueSearch:String):AsyncToken // returns String[]
		{
			return invoke(findPublicFieldValues, arguments);
		}
		
		////////////////////////////////////
		// string and numeric data columns
		
		public function getColumn(columnId:Object, minParam:Number, maxParam:Number, sqlParams:Array):AsyncToken
		{
			return invoke(getColumn, arguments, AttributeColumnData);
		}
		
		/////////////////////
		// Geometry columns
		
		public function getGeometryStreamTileDescriptors(columnId:int):AsyncToken
		{
			return invoke(getGeometryStreamTileDescriptors, arguments, GeometryStreamMetadata);
		}
		public function getGeometryStreamMetadataTiles(columnId:int, tileIDs:Array):AsyncToken // returns byte[]
		{
			return invoke(getGeometryStreamMetadataTiles, arguments);
		}
		public function getGeometryStreamGeometryTiles(columnId:int, tileIDs:Array):AsyncToken // returns byte[]
		{
			return invoke(getGeometryStreamGeometryTiles, arguments);
		}
		
		public function createTileService(columnId:int):IWeaveGeometryTileService
		{
			var tileService:IWeaveGeometryTileService = new WeaveGeometryTileServlet(this, columnId);
			
			// when we dispose this servlet, we also want to dispose the spawned tile servlet
			registerDisposableChild(this, tileService);
			
			return tileService;
		}
		
		//////////////
		// Row query
		
		public function getRows(keys:Array):AsyncToken // returns WeaveRecordList
		{
			var keysArray:Array = [];
			for each( var key:IQualifiedKey in keys)
			{
				keysArray.push(key.localName);
			}
			var keytype:String = (keys[0] as IQualifiedKey).keyType;
			return invoke(getRows,[keytype,keysArray]);
		}
		
		////////////////////////////
		// backwards compatibility
		
		/**
		 * Deprecated. Use getColumn() instead.
		 */
		public function getColumnFromMetadata(metadata:Object):AsyncToken
		{
			return invoke(getColumnFromMetadata, arguments, AttributeColumnData);
		}
	}
}


import mx.rpc.AsyncToken;

import weave.api.services.IWeaveGeometryTileService;
import weave.services.WeaveDataServlet;

/**
 * This is an implementation of IWeaveGeometryTileService that uses a WeaveDataServlet as the tile source.
 * 
 * @author adufilie
 */
internal class WeaveGeometryTileServlet implements IWeaveGeometryTileService
{
	public function WeaveGeometryTileServlet(service:WeaveDataServlet, columnId:int)
	{
		_service = service;
		_columnId = columnId;
	}
	
	private var _service:WeaveDataServlet;
	private var _columnId:int;
	
	public function getMetadataTiles(tileIDs:Array):AsyncToken
	{
		var token:AsyncToken = _service.getGeometryStreamMetadataTiles(_columnId, tileIDs);
		WeaveAPI.ProgressIndicator.addTask(token, this);
		return token;
	}
	
	public function getGeometryTiles(tileIDs:Array):AsyncToken
	{
		var token:AsyncToken = _service.getGeometryStreamGeometryTiles(_columnId, tileIDs);
		WeaveAPI.ProgressIndicator.addTask(token, this);
		return token;
	}
}
