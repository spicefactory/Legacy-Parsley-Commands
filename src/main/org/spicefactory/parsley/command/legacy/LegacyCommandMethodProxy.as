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

import org.spicefactory.lib.command.lifecycle.CommandLifecycle;
import org.spicefactory.lib.command.proxy.DefaultCommandProxy;
import org.spicefactory.lib.reflect.Method;
import org.spicefactory.parsley.core.command.ManagedCommandProxy;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.core.context.provider.ObjectProvider;
import org.spicefactory.parsley.dsl.command.ManagedCommandLifecycle;
/**
 * @author Jens Halm
 */
public class LegacyCommandMethodProxy extends DefaultCommandProxy implements ManagedCommandProxy {


	private var provider: ObjectProvider;
	private var method: Method;
	
	private var context: Context;
	private var messageProperties: Array;
	

	function LegacyCommandMethodProxy (provider: ObjectProvider, method: Method, context: Context, messageProperties: Array) {
		this.provider = provider;
		this.method = method;
		this.context = context;
		this.messageProperties = messageProperties;
	}

	public function get id () : String {
		return "[noId]";
	}
	
	protected override function createLifecycle () : CommandLifecycle {
		return new ManagedCommandLifecycle(context, this);
	}
	
	/**
	 * @private
	 */
	protected override function doExecute () : void {
		target = new LegacyCommandAdapter(provider.instance, method);
		super.doExecute();
	}
	

}
}
