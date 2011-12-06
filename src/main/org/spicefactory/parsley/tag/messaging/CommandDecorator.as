/*
 * Copyright 2009 the original author or authors.
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

package org.spicefactory.parsley.tag.messaging {

import org.spicefactory.lib.errors.IllegalStateError;
import org.spicefactory.lib.reflect.Method;
import org.spicefactory.lib.reflect.Parameter;
import org.spicefactory.parsley.config.ObjectDefinitionDecorator;
import org.spicefactory.parsley.dsl.ObjectDefinitionBuilder;
import org.spicefactory.parsley.tag.util.ReflectionUtil;

[Metadata(name="Command", types="method", multiple="true")]
/**
 * Represents a Metadata, MXML or XML tag that can be used on methods which wish to execute asynchronous
 * commands triggered by messages.
 * 
 * @author Jens Halm
 */
public class CommandDecorator extends MessageReceiverDecoratorBase implements ObjectDefinitionDecorator {


	[Ignore]
	/**
	 * Optional list of names of properties of the message that should be used as method parameters
	 * instead passing the message itself as a parameter.
	 */
	public var messageProperties:Array;

	[Target]
	/**
	 * The name of the method that wishes to handle the message.
	 */
	public var method:String;
	
	
	/**
	 * @inheritDoc
	 */
	public function decorate (builder:ObjectDefinitionBuilder) : void {

		var targetMethod: Method = ReflectionUtil.getMethod(method, builder.typeInfo);
		validateMethod(targetMethod);
		
		if (!type) type = deduceMessageType(targetMethod);
			
		var f: ReceiverFactory = new ReceiverFactory(targetMethod, builder.config.context, type, selector, order, messageProperties);
		builder.lifecycle().messageReceiverFactory(f, scope);
			
	}
	
	private function validateMethod (method: Method): void {
		var paramCount: int = method.parameters.length;
		if (!messageProperties && paramCount > 1) {
			throw new IllegalStateError("At most one parameter allowed on method with name " + method 
					+ " on target type " + type.name);
		}
	}
	
	private function deduceMessageType (method: Method) : Class {
		var params: Array = method.parameters;
		return (params.length > 0) ? Parameter(params[0]).type.getClass() : Object;
	}
	
	
}
}

import org.spicefactory.lib.reflect.ClassInfo;
import org.spicefactory.lib.reflect.Method;
import org.spicefactory.parsley.command.legacy.LegacyCommandMethodProxy;
import org.spicefactory.parsley.core.command.ManagedCommandFactory;
import org.spicefactory.parsley.core.command.ManagedCommandProxy;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.core.context.provider.ObjectProvider;
import org.spicefactory.parsley.core.messaging.receiver.MessageReceiver;
import org.spicefactory.parsley.dsl.command.MappedCommandProxy;
import org.spicefactory.parsley.processor.messaging.MessageReceiverFactory;

class ReceiverFactory implements MessageReceiverFactory {

	private var method: Method;
	private var context: Context;
	
	private var messageType: Class;
	private var selector: *;
	private var order: int;
	
	private var messageProperties: Array;

	function ReceiverFactory (method: Method, context: Context, messageType: Class, selector: *, order: int, messageProperties: Array) {
		this.method = method;
		this.context = context;
		this.messageType = messageType;
		this.selector = selector;
		this.order = order;	
		this.messageProperties = messageProperties;
	}

	public function createReceiver (provider: ObjectProvider): MessageReceiver {
		var factory: CommandFactory = new CommandFactory(provider, method, context, messageProperties);
		return new MappedCommandProxy(factory, context, messageType, selector, order);
	}
	
	
}

class CommandFactory implements ManagedCommandFactory {

	private var provider: ObjectProvider;
	private var method: Method;
	
	private var context: Context;
	private var messageProperties: Array;
	
	function CommandFactory (provider: ObjectProvider, method: Method, context: Context, messageProperties: Array) {
		this.provider = provider;
		this.method = method;
		this.context = context;
		this.messageProperties = messageProperties;
	}

	public function newInstance (): ManagedCommandProxy {
		return new LegacyCommandMethodProxy(provider, method, context, messageProperties);
	}

	public function get type (): ClassInfo {
		return provider.type;
	}
	
}

