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

import org.spicefactory.lib.reflect.Method;
import org.spicefactory.parsley.core.registry.DynamicObjectDefinition;
/**
 * @author Jens Halm
 */
public class LegacyDynamicCommandDefinition {
	
	
	private var _targetDef: DynamicObjectDefinition;
	
	private var _executeMethod: Method;
	private var _resultMethod: Method;
	private var _errorMethod: Method;
	private var _messageProperties: Array;


	function LegacyDynamicCommandDefinition (targetDef: DynamicObjectDefinition,
			executeMethod: Method,
			resultMethod: Method,
			errorMethod: Method,
			messageProperties: Array) {
		_targetDef = targetDef;
		_executeMethod = executeMethod;
		_resultMethod = resultMethod;
		_errorMethod = errorMethod;
		_messageProperties = messageProperties;	
	}


	public function get targetDef (): DynamicObjectDefinition {
		return _targetDef;
	}

	public function get executeMethod (): Method {
		return _executeMethod;
	}

	public function get resultMethod (): Method {
		return _resultMethod;
	}

	public function get errorMethod (): Method {
		return _errorMethod;
	}

	public function get messageProperties (): Array {
		return _messageProperties;
	}
	
}
}
