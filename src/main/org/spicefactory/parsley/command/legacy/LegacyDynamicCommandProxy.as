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

import org.spicefactory.lib.command.CommandResult;
import org.spicefactory.lib.command.lifecycle.CommandLifecycle;
import org.spicefactory.lib.command.proxy.DefaultCommandProxy;
import org.spicefactory.parsley.core.command.ManagedCommandProxy;
import org.spicefactory.parsley.core.context.DynamicObject;
import org.spicefactory.parsley.dsl.command.ManagedCommandLifecycle;
/**
 * @author Jens Halm
 */
public class LegacyDynamicCommandProxy extends DefaultCommandProxy implements ManagedCommandProxy {


	private var def: LegacyDynamicCommandDefinition;
	
	private var dynamicObject:DynamicObject;


	function LegacyDynamicCommandProxy (def: LegacyDynamicCommandDefinition) {
		this.def = def;
	}

	public function get id () : String {
		return def.targetDef.id;
	}
	
	protected override function createLifecycle () : CommandLifecycle {
		return new ManagedCommandLifecycle(def.targetDef.registry.context, this);
	}
	
	/**
	 * @private
	 */
	protected override function doExecute () : void {
		dynamicObject = def.targetDef.registry.context.addDynamicDefinition(def.targetDef);
		target = new LegacyCommandAdapter(dynamicObject.instance, def.executeMethod, def.resultMethod, def.errorMethod, def.messageProperties);
		super.doExecute();
	}
	
	/**
	 * @private
	 */
	protected override function commandComplete (result:CommandResult) : void {
		super.commandComplete(result);
		dynamicObject.remove();
	}
	
	/**
	 * @private
	 */
	public override function cancel () : void {
		super.cancel();
		dynamicObject.remove();
	}
	
	/**
	 * @private
	 */
	protected override function error (cause: Object = null): void {
		super.error(cause);
		dynamicObject.remove();
	}


}
}
