package org.spicefactory.parsley.command {

import org.spicefactory.parsley.comobserver.CommandComplete;
import org.hamcrest.assertThat;
import org.hamcrest.object.equalTo;
import org.spicefactory.lib.command.result.ResultProcessors;
import org.spicefactory.parsley.command.mock.MockResult;
import org.spicefactory.parsley.command.mock.MockResultProcessor;
import org.spicefactory.parsley.command.model.DynamicCommandObserverOrder;
import org.spicefactory.parsley.command.model.OrderBuilder;
import org.spicefactory.parsley.command.model.OrderedMixedScopeCompleteHandlers;
import org.spicefactory.parsley.context.ContextBuilder;
import org.spicefactory.parsley.core.builder.ObjectDefinitionBuilder;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.core.registry.DynamicObjectDefinition;
import org.spicefactory.parsley.core.scope.ScopeName;
import org.spicefactory.parsley.dsl.messaging.impl.DynamicCommandBuilder;

/**
 * @author Jens Halm
 */
public class DynamicCommandScopeAndOrderTest {
	
	
	[BeforeClass]
	public static function registerMockCommandFactory () : void {
		if (!ResultProcessors.forResultType(MockResult).exists) {
			ResultProcessors.forResultType(MockResult).processorType(MockResultProcessor);
		}
	}
	
	
	[Test]
	public function commandResultOrder () : void {
		MockResultProcessor.reset();
		
		var order:OrderBuilder = new OrderBuilder();
		DynamicCommandObserverOrder.order = order;
		OrderedMixedScopeCompleteHandlers.order = order;
		
		var handlerParent:OrderedMixedScopeCompleteHandlers = new OrderedMixedScopeCompleteHandlers("-PAR");
		var handlerChild:OrderedMixedScopeCompleteHandlers = new OrderedMixedScopeCompleteHandlers("-CHI");
		var parentBuilder:ContextBuilder = ContextBuilder.newSetup().newBuilder();
		var def:DynamicObjectDefinition 
				= parentBuilder.objectDefinition().forClass(DynamicCommandObserverOrder).asDynamicObject().build();
		DynamicCommandBuilder.newBuilder(def).build();
		buildCompleteHandlers(parentBuilder, handlerParent, ["1", "3", "5", "7"]);
		var parent:Context = parentBuilder.build();
		var childBuilder:ContextBuilder = ContextBuilder.newSetup().parent(parent).newBuilder();
		buildCompleteHandlers(childBuilder, handlerChild, ["2", "4", "6"]);
		var child:Context = childBuilder.build();
		
		child.scopeManager.dispatchMessage("foo");
		assertThat(order.value, equalTo("-EXE"));
		MockResultProcessor.dispatchAll();
		assertThat(order.value, equalTo("-EXE-DYN-CHI:I-CHI:A-PAR:B-CHI:B-CHI:C-PAR:D-CHI:D"));
	}
	
	private function buildCompleteHandlers (contextBuilder:ContextBuilder, instance:Object, order:Array) : void {
		var builder:ObjectDefinitionBuilder = contextBuilder.objectDefinition().forInstance(instance);
		CommandComplete.forMethod("handleLocalCommand").scope(ScopeName.LOCAL).order(order[0]).apply(builder); 	// :A
		CommandComplete.forMethod("handleGlobalCommand").order(order[1]).apply(builder);						// :B
		CommandComplete.forMethod("handleLocalCommand2").scope(ScopeName.LOCAL).order(order[2]).apply(builder);	// :C
		if (order.length > 3) {
			CommandComplete.forMethod("handleGlobalCommand2").order(order[3]).apply(builder);					// :D
		}
		else {
			CommandComplete.forMethod("handleGlobalCommand2").apply(builder);									// :D
		}
		CommandComplete.forMethod("interceptLocalCommand").scope(ScopeName.LOCAL).apply(builder);				// :I
		builder.asSingleton().register();
	}
	
	
}
}
