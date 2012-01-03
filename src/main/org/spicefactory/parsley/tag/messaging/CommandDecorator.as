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
import org.spicefactory.lib.reflect.ClassInfo;
import org.spicefactory.lib.reflect.Method;
import org.spicefactory.lib.reflect.Parameter;
import org.spicefactory.parsley.core.builder.ObjectDefinitionBuilder;
import org.spicefactory.parsley.core.builder.ObjectDefinitionDecorator;
import org.spicefactory.parsley.messaging.processor.MethodReceiverProcessor;
import org.spicefactory.parsley.messaging.receiver.MessageReceiverInfo;
import org.spicefactory.parsley.messaging.tag.MessageReceiverDecoratorBase;

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

		var targetMethod: Method = builder.typeInfo.getMethod(method);
		if (!targetMethod) {
			throw new IllegalStateError("Target class " + builder.typeInfo.name 
					+ " does not contain a method with name " + method);
		}
		validateMethod(targetMethod);
		
		if (!type) type = deduceMessageType(targetMethod);
		
		var info: MessageReceiverInfo = new MessageReceiverInfo();
		info.type = ClassInfo.forClass(type, builder.registry.domain);
		info.selector = selector;
		info.order = order;
			
		var factory:Function = function (): Object {
			var factory: CommandFactory = new CommandFactory(targetMethod, builder.registry.context, messageProperties);
			return new MethodCommandProxy(factory, builder.registry.context, info);
		};
		
		builder.method(method).process(new MethodReceiverProcessor(factory, scope));
			
	}
	
	private function validateMethod (method: Method): void {
		var paramCount: int = method.parameters.length;
		if (!messageProperties && paramCount > 1) {
			throw new IllegalStateError("At most one parameter allowed on method with name " + method 
					+ " on target type " + type);
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
import org.spicefactory.parsley.command.impl.MappedCommandProxy;
import org.spicefactory.parsley.command.legacy.LegacyCommandMethodProxy;
import org.spicefactory.parsley.core.command.ManagedCommandFactory;
import org.spicefactory.parsley.core.command.ManagedCommandProxy;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.core.context.provider.ObjectProvider;
import org.spicefactory.parsley.messaging.receiver.MessageReceiverInfo;
import org.spicefactory.parsley.messaging.receiver.MethodReceiver;

class CommandFactory implements ManagedCommandFactory {

	public var provider: ObjectProvider;
	private var method: Method;
	
	private var context: Context;
	private var messageProperties: Array;
	
	function CommandFactory (method: Method, context: Context, messageProperties: Array) {
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

class MethodCommandProxy extends MappedCommandProxy implements MethodReceiver {


	private var factory: CommandFactory;

	function MethodCommandProxy (factory: CommandFactory, context: Context, info: MessageReceiverInfo) {
		super(factory, context, info);
		this.factory = factory;
	}
	
	public function init (provider: ObjectProvider, method: Method): void {
		factory.provider = provider;
	}
	
}

