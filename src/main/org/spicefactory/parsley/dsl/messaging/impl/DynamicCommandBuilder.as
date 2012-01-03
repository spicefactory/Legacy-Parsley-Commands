/*
 * Copyright 2010 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.spicefactory.parsley.dsl.messaging.impl {

import org.spicefactory.lib.errors.IllegalStateError;
import org.spicefactory.lib.reflect.ClassInfo;
import org.spicefactory.lib.reflect.Method;
import org.spicefactory.lib.reflect.Parameter;
import org.spicefactory.parsley.command.impl.MappedCommandProxy;
import org.spicefactory.parsley.command.legacy.LegacyDynamicCommandDefinition;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.core.events.ContextEvent;
import org.spicefactory.parsley.core.messaging.receiver.MessageTarget;
import org.spicefactory.parsley.core.registry.DynamicObjectDefinition;
import org.spicefactory.parsley.messaging.receiver.MessageReceiverInfo;

/**
 * A builder for a DynamicCommand, a short-lived object that gets created for a matching message
 * and disposed after the (usually asynchronous) command execution.
 * 
 * <p>A dynamic command is a special type of object that only gets created when a matching
 * message was dispatched. It contains only a single command execution method and optionally 
 * "private" result and error handlers that will only be called for the command executed 
 * by the same instance. In addition other object can listen for the result or error
 * values with the regular <code>[CommandResult]</code> or <code>[CommandError]</code> tags.</p>
 * 
 * <p>If the <code>stateful</code> property is false (the default) a new instance will 
 * be created for each matching message and the command object will be disposed 
 * and removed from the Context as soon as the asynchronous command completed.</p>
 *  
 * @author Jens Halm
 */
public class DynamicCommandBuilder {


	private var info:MessageReceiverInfo;

	private var _scope:String;
	private var _messageType:Class;
	private var _messageProperties:Array;
	
	private var _execute:String = "execute";
	private var _result:String;
	private var _error:String;
	
	private var targetDef:DynamicObjectDefinition;
	private var target:MessageTarget;


	/**
	 * Creates a new builder for the specified target object.
	 * 
	 * @param targetDef the definition for the command objects
	 * @return a new builder for a dynamic command
	 */
	public static function newBuilder (targetDef:DynamicObjectDefinition) : DynamicCommandBuilder {
		return new DynamicCommandBuilder(targetDef); 
	}
	
	
	/**
	 * @private
	 */
	function DynamicCommandBuilder (targetDef:DynamicObjectDefinition) {
		this.targetDef = targetDef; 
		this.info = new MessageReceiverInfo();
	}
	

	/**
	 * The name of the scope the dynamic command listens to.
	 * 
	 * @param value the name of the scope the dynamic command listens to
	 * @return this builder for method chaining
	 */
	public function scope (value:String) : DynamicCommandBuilder {
		_scope = value;
		return this;
	}

	/**
	 * The type of the messages the dynamic command wants to handle.
	 * 
	 * @param value type of the messages the dynamic command wants to handle
	 * @return this builder for method chaining
	 */
	public function messageType (value:Class) : DynamicCommandBuilder {
		_messageType = value;
		return this;
	}

	/**
	 * An optional selector value to be used in addition to selecting messages by type.
	 * Will be checked against the value of the property in the message marked with <code>[Selector]</code>
	 * or against the event type if the message is an event and does not have a selector property specified explicitly.
	 * 
	 * @param value an optional selector value to be used in addition to selecting messages by type
	 * @return this builder for method chaining
	 */
	public function selector (value:*) : DynamicCommandBuilder {
		info.selector = value;
		return this;
	}
	
	/**
	 * Optional list of names of properties of the message that should be used as method parameters
	 * instead passing the message itself as a parameter.
	 * 
	 * @param value list of names of properties of the message that should be used as method parameters
	 * @return this builder for method chaining
	 */
	public function messageProperties (value:Array) : DynamicCommandBuilder {
		_messageProperties = value;
		return this;
	}
		
	/**
	 * The execution order for this receiver. Will be processed in ascending order. 
	 * <p>The default is <code>int.MAX_VALUE</code>.</p>
	 * 
	 * @param value the execution order for this receiver
	 * @return this builder for method chaining
	 */
	public function order (value:int) : DynamicCommandBuilder {
		info.order = value;
		return this;
	}
	
	/**
	 * The name of the method that executes the command.
	 * If omitted the default is "execute".
	 * The presence of an execution method in the 
	 * target instance is required.
	 * 
	 * @param value the name of the method that executes the command
	 * @return this builder for method chaining
	 */
	public function execute (value:String) : DynamicCommandBuilder {
		_execute = value;
		return this;
	}
	
	/**
	 * The name of the method to invoke for the result.
	 * If omitted the framework will look for a method named "result".
	 * A result method is optional, if it does not exist no result will
	 * be passed to the command instance. 
	 *
	 * @param value the name of the method to invoke for the result.
	 * @return this builder for method chaining
	 */
	public function result (value:String) : DynamicCommandBuilder {
		_result = value;
		return this;
	}
	
	/**
	 * The name of the method to invoke in case of errors.
	 * If omitted the framework will look for a method named "error".
	 * An error method is optional, if it does not exist no error value will
	 * be passed to the command instance.
	 *  
	 * @param value the name of the method to invoke in case of errors.
	 * @return this builder for method chaining
	 */
	public function error (value:String) : DynamicCommandBuilder {
		_error = value;
		return this;
	}
	
	
	/**
	 * Builds and registers the dynamic command.
	 */
	public function build () : void {
		
		if (_result == null && targetDef.type.getMethod("result") != null) {
			_result = "result";
		}
		if (_error == null && targetDef.type.getMethod("error") != null) {
			_error = "error";
		}
		var executeMethod: Method = getMethod(_execute, 1);
		var resultMethod: Method = getMethod(_result, 3);
		var errorMethod: Method = getMethod(_error, 3);
		
		if (!_messageType) _messageType = deduceMessageType();
		info.type = ClassInfo.forClass(_messageType, targetDef.registry.domain);
		
		var def: LegacyDynamicCommandDefinition 
				= new LegacyDynamicCommandDefinition(targetDef, executeMethod, resultMethod, errorMethod, _messageProperties);
		var factory: Factory = new Factory(def);
		target = new MappedCommandProxy(factory, targetDef.registry.context, info);
				
		targetDef.registry.context.scopeManager.getScope(_scope).messageReceivers.addTarget(target);
		
		targetDef.registry.context.addEventListener(ContextEvent.DESTROYED, contextDestroyed);
	}

	
	private function contextDestroyed (event:ContextEvent) : void {
		Context(event.target).scopeManager.getScope(_scope).messageReceivers.removeTarget(target);
	}
	
	private function getMethod (name: String, maxParams: int): Method {
		if (!name) return null;
		
		var method: Method = targetDef.type.getMethod(name);
		if (!method) {
			throw new IllegalStateError("No method with name " + name 
					+ " defined on target type " + targetDef.type.name);
		}
		var paramCount: int = method.parameters.length;
		if (!_messageProperties && paramCount > maxParams) {
			throw new IllegalStateError("At most " + maxParams + " parameter(s) allowed on method with name " + name 
					+ " on target type " + targetDef.type.name);
		}
		return method;
	}
	
	private function deduceMessageType () : Class {
		var params: Array = targetDef.type.getMethod(_execute).parameters;
		return (params.length > 0) ? Parameter(params[0]).type.getClass() : Object;
	}
	
	
}
}

import org.spicefactory.lib.reflect.ClassInfo;
import org.spicefactory.parsley.command.legacy.LegacyDynamicCommandDefinition;
import org.spicefactory.parsley.command.legacy.LegacyDynamicCommandProxy;
import org.spicefactory.parsley.core.command.ManagedCommandFactory;
import org.spicefactory.parsley.core.command.ManagedCommandProxy;

class Factory implements ManagedCommandFactory {

	private var def: LegacyDynamicCommandDefinition;
	
	function Factory (def: LegacyDynamicCommandDefinition) {
		this.def = def;
	}

	public function newInstance (): ManagedCommandProxy {
		return new LegacyDynamicCommandProxy(def);
	}

	public function get type (): ClassInfo {
		return def.targetDef.type;
	}
	
}

