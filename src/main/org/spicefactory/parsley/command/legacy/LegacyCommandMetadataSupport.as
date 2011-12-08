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

import org.spicefactory.lib.reflect.Metadata;
import org.spicefactory.parsley.tag.messaging.CommandDecorator;

/**
 * Provides a static method to initalize the support for the Command metadata tag as it has been 
 * part of Parsley 2.
 * Can be used as a child tag of a <code>&lt;ContextBuilder&gt;</code> tag in MXML alternatively.
 * 
 * @author Jens Halm
 */
public class LegacyCommandMetadataSupport {
	
	
	private static var initialized:Boolean = false;
	
	
	/**
	 * Initializes the support for the Command metadata tag as it has been part of Parsley 2.
	 * Must be invoked before a <code>ContextBuilder</code> is used for the first time.
	 */
	public static function initialize () : void {
		if (initialized) return;
		
		Metadata.registerMetadataClass(CommandDecorator);
		
		initialized = true;
	}
	
	
}
}