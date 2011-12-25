/*
 * Copyright 2011 the original author or authors.
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
package org.spicefactory.parsley.command.legacy {

	import org.spicefactory.lib.command.light.LightCommandAdapter;
	import org.spicefactory.lib.command.CommandResult;
	import org.spicefactory.lib.command.adapter.CommandAdapter;
	import org.spicefactory.lib.command.base.AbstractSuspendableCommand;
	import org.spicefactory.lib.command.base.DefaultCommandResult;
	import org.spicefactory.lib.command.builder.CommandProxyBuilder;
	import org.spicefactory.lib.command.data.CommandData;
	import org.spicefactory.lib.command.data.DefaultCommandData;
	import org.spicefactory.lib.command.events.CommandEvent;
	import org.spicefactory.lib.command.events.CommandFailure;
	import org.spicefactory.lib.command.lifecycle.CommandLifecycle;
	import org.spicefactory.lib.command.lifecycle.DefaultCommandLifecycle;
	import org.spicefactory.lib.command.proxy.CommandProxy;
	import org.spicefactory.lib.command.result.ResultProcessors;
	import org.spicefactory.lib.logging.LogContext;
	import org.spicefactory.lib.logging.Logger;
	import org.spicefactory.lib.reflect.Method;
	import org.spicefactory.lib.reflect.Parameter;
	import org.spicefactory.lib.reflect.types.Void;
	import org.spicefactory.parsley.core.errors.ContextError;
	import org.spicefactory.parsley.core.messaging.Message;
	import org.spicefactory.parsley.core.messaging.MessageState;
	import org.spicefactory.parsley.dsl.command.ManagedCommandLifecycle;
/**
 * @author Jens Halm
 */
public class LegacyCommandAdapter extends AbstractSuspendableCommand implements CommandAdapter {


	private static const log: Logger = LogContext.getLogger(LegacyCommandAdapter);


	private var _target:Object;
	
	private var executeMethod:Method;
	private var resultMethod:Method;
	private var errorMethod:Method;
	
	private var _lifecycle:CommandLifecycle;
	private var _data:DefaultCommandData;
	
	private var resultProcessor: CommandProxy;
	
	private var messageProperties: Array;
	
	
	function LegacyCommandAdapter (target:Object, 
			executeMethod:Method, 
			resultMethod:Method = null, 
			errorMethod:Method = null, 
			messageProperties:Array = null) {
		_target = target;
		this.executeMethod = executeMethod;
		this.resultMethod = resultMethod;
		this.errorMethod = errorMethod;
		this.messageProperties = messageProperties;
		_data = new DefaultCommandData();
	}


	public function get target () : Object {
		return _target;
	}

	public function get cancellable () : Boolean {
		return (resultProcessor) ? resultProcessor.cancellable : false;
	}

	public function get suspendable () : Boolean {
		return false;
	}
	
	public function prepare (lifecycle:CommandLifecycle, data:CommandData) : void {
		_lifecycle = lifecycle;
		_data = new DefaultCommandData(data);
	}
	
	protected function get lifecycle () : CommandLifecycle {
		if (!_lifecycle) {
			_lifecycle = new DefaultCommandLifecycle();
		}
		return _lifecycle;
	}
    
    protected function get data () : CommandData {
    	if (!_data) {
    		_data = new DefaultCommandData();
    	}
    	return _data;
    }
	
	protected override function doExecute () : void {
		lifecycle.beforeExecution(target, data);
		var params:Array = getParameters();
		try {
			if (executeMethod.returnType.getClass() != Void) {
				var result:Object = executeMethod.invoke(target, params);
				handleResult(result);
			}
			else {
				executeMethod.invoke(target, params);
				handleResult(null);
			}
		}
		catch (e:Error) {
			afterCompletion(DefaultCommandResult.forError(target, e));
			error(e);
		}
	}
	
	private function getParameters () : Array {
		var message:Object = data.getObject();
		
		if (messageProperties) return getMessageProperties(message);
		
		var params:Array = [];
		if (executeMethod.parameters.length) {
			params.push(message);
		}
		return params;
	}
	
	private function getMessageProperties (message:Object) : Array {
		var params:Array = [];
		var requiredParams:uint = 0;
		for each (var param:Parameter in executeMethod.parameters) {
			if (param.required) requiredParams++;
		}
		if (requiredParams > messageProperties.length) {
			throw new ContextError("Number of specified parameter names does not match the number of required parameters of " 
				+ executeMethod + ". Required: " + requiredParams + " - actual: " + messageProperties.length);
		}
		this.messageProperties = new Array();
		for each (var propertyName:String in messageProperties) {
			if (!message.hasOwnProperty(propertyName)) {
				throw new ContextError("Message " + message 
						+ " does not contain a property with name " + propertyName);	
			}
			params.push(message[propertyName]);
		}
		return params;
	}
	
 	private function handleResult (result: Object): void {
 		var builder:CommandProxyBuilder = (result) ? ResultProcessors.newProcessor(target, result) : null;
		if (builder) {
			processResult(builder);
		}
		else {
			handleCompletion(result);				
		}
 	}
 	
 	private function handleCompletion (result: Object): void {
 		if (resultMethod) invoke(resultMethod, result);
 		else doHandleCompletion(result);
 	}
 	
 	private function handleError (cause: Object): void {
 		if (cause is CommandFailure) cause = CommandFailure(cause).rootCause;
 		if (errorMethod) invoke(errorMethod, cause); 
 		else doHandleError(cause);
 	}
 	
 	public function doHandleCompletion (result: Object): void {
 		afterCompletion(DefaultCommandResult.forCompletion(target, result));
 		resultProcessor = null;
 		complete(result);
 	}
 	
 	public function doHandleError (cause: Object): void {
 		afterCompletion(DefaultCommandResult.forError(target, cause));
		resultProcessor = null;
		error(cause);
 	}
 	
 	public function handleCancellation (): void {
 		// do not call cancel to bypass doCancel
		afterCompletion(DefaultCommandResult.forCancellation(target));
		resultProcessor = null;
 		dispatchEvent(new CommandEvent(CommandEvent.CANCEL));	
 	}
 	
 	private function processResult (builder: CommandProxyBuilder): void {
 		resultProcessor = builder
 			.domain(executeMethod.owner.applicationDomain)
 			.result(function (result: Object): void { 
 				handleCompletion(result); })
 			.error(function (cause: Object): void { 
 				handleError(cause); })
 			.cancel(function (): void { 
 				handleCancellation(); })
 			.execute();
 	}
 	
 	private function invoke (method: Method, value: Object): void {
 		var params: Array = [];
 		var paramCount: int = method.parameters.length;
		var processor: Processor;
		
 		if (paramCount >= 1) params.push(value);
 		if (paramCount >= 2) params.push(data.getObject());
 		if (paramCount >= 3) {
 			processor = createProcessor(value);
 			params.push(processor);
 		}
 		
 		try {
 			method.invoke(target, params);
 		}
 		catch (e: Error) {
 			log.error("Error invoking {0}: {1}", method, e);
 		}
 		
 		if (processor) processor.done = true;
 		if (!processor || processor.state == MessageState.ACTIVE) {
 			var result: Object = (processor) ? processor.result : value;
 			if (LightCommandAdapter.isErrorType(result)) doHandleError(result);
 			else doHandleCompletion(result);
 		}
 	}
 	
 	private function createProcessor (result: Object): Processor {
 		var message: Message = (lifecycle is ManagedCommandLifecycle)
 			? ManagedCommandLifecycle(lifecycle).trigger : null;
 		return new Processor(target, message, result, this);
 	}
 	
 	private function afterCompletion (cr: CommandResult): void {
 		lifecycle.afterCompletion(target, cr);
 	}
 	
	protected override function doCancel () : void {
		if (resultProcessor) 
		{
			resultProcessor.cancel();
			resultProcessor = null;
		}
		afterCompletion(DefaultCommandResult.forCancellation(this));
	}


}
}

import org.spicefactory.lib.command.light.LightCommandAdapter;
import org.spicefactory.lib.errors.IllegalStateError;
import org.spicefactory.lib.logging.LogContext;
import org.spicefactory.lib.logging.Logger;
import org.spicefactory.parsley.command.legacy.LegacyCommandAdapter;
import org.spicefactory.parsley.core.command.CommandObserverProcessor;
import org.spicefactory.parsley.core.command.CommandStatus;
import org.spicefactory.parsley.core.messaging.Message;
import org.spicefactory.parsley.core.messaging.MessageState;

class Processor implements CommandObserverProcessor {


	private static const log: Logger = LogContext.getLogger(LegacyCommandAdapter);

    private var _command: Object;
	private var _message: Message;
	private var _result: Object;
	private var _status: CommandStatus;
	private var adapter: LegacyCommandAdapter;

	private var _state: MessageState;
	
	public var done: Boolean;


	function Processor (command: Object, message: Message, result: Object, adapter: LegacyCommandAdapter) {
		_command = command;
		_message = message;
		_result = result;
		_state = MessageState.ACTIVE;
		setStatus();
		this.adapter = adapter;
	}
	

	public function get command (): Object {
		return _command;
	}
	
	public function get root (): Boolean {
		return true;
	}

	public function get commandStatus (): CommandStatus {
		return _status;
	}


	public function get result (): Object {
		return _result;
	}
	
	public function changeResult (result: Object, error: Boolean = false): void {
		if (error && !LightCommandAdapter.isErrorType(result)) {
			log.warn("Marking the result as an error does not have any effect in legacy commands." +
				" Instead the type of the result object must be one of the recognized error types (e.g. Error," +
				" ErrorEvent, Fault or a custom error type registered with LightCommandAdapter.addErrorType");
		}
		_result = result;
		setStatus();
	}
	
	private function setStatus (): void {
		_status = (LightCommandAdapter.isErrorType(result)) ? CommandStatus.ERROR : CommandStatus.COMPLETE;
	}


	public function get message (): Message {
		return _message;
	}

	public function get state (): MessageState {
		return _state;
	}
	

	public function rewind (): void {
		log.warn("rewind does not have any effect inside legacy dynamic commands");
	}

	public function sendResponse (msg: Object, selector: * = null): void {
		if (message) {
			message.senderContext.scopeManager.dispatchMessage(msg, selector);
		}
		else {
			throw new IllegalStateError("Sender Context is unknown");
		}
	}


	public function suspend (): void {
		if (_state == MessageState.CANCELLED) {
			throw new IllegalStateError("Processor has already been cancelled");
		}
		_state = MessageState.SUSPENDED;
	}
	
	public function resume (): void {
		if (_state == MessageState.CANCELLED) {
			throw new IllegalStateError("Processor has already been cancelled");
		}
		if (_state != MessageState.SUSPENDED) {
			throw new IllegalStateError("Processor has not been suspended");
		}
		_state = MessageState.ACTIVE;
		if (done) {
			if (LightCommandAdapter.isErrorType(result)) adapter.doHandleError(result);
			else adapter.doHandleCompletion(result);
		}
	}
	
	public function cancel (): void {
		if (_state == MessageState.CANCELLED) {
			return;
		}
		_state = MessageState.CANCELLED;
		adapter.handleCancellation();
	}

	
}


