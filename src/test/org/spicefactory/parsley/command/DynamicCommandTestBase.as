package org.spicefactory.parsley.command {

import org.flexunit.assertThat;
import org.hamcrest.collection.arrayWithSize;
import org.hamcrest.object.equalTo;
import org.spicefactory.lib.command.result.ResultProcessors;
import org.spicefactory.lib.errors.AbstractMethodError;
import org.spicefactory.parsley.command.mock.MockResult;
import org.spicefactory.parsley.command.mock.MockResultProcessor;
import org.spicefactory.parsley.command.model.DynamicCommand;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.core.scope.ScopeManager;
import org.spicefactory.parsley.messaging.messages.TestEvent;

/**
 * @author Jens Halm
 */
public class DynamicCommandTestBase {
	
	
	private var context:Context;
	
	
	[BeforeClass]
	public static function registerMockCommandFactory () : void {
		if (!ResultProcessors.forResultType(MockResult).exists) {
			ResultProcessors.forResultType(MockResult).processorType(MockResultProcessor);
		}
	}
	
	
	[Before]
	public function setUp () : void {
		MockResultProcessor.reset();
		DynamicCommand.instances = new Array();
		context = commandContext;
	}
	
	[Test]
	public function withResultHandler () : void {
		var sm:ScopeManager = context.scopeManager;
		assertThat(DynamicCommand.instances, arrayWithSize(0));
		
		sm.dispatchMessage("some message");
		sm.dispatchMessage(new TestEvent("command1", "str", 0));
		assertThat(DynamicCommand.instances, arrayWithSize(1));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 0, 1);
		
		sm.dispatchMessage("some message");
		assertThat(DynamicCommand.instances, arrayWithSize(1));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 1, 1);
		
		sm.dispatchMessage(new TestEvent("command1", "str", 0));
		assertThat(DynamicCommand.instances, arrayWithSize(2));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 1, 1);
		validateCommand(DynamicCommand.instances[1] as DynamicCommand, 0, 1);
		
		sm.dispatchMessage("some message");
		assertThat(DynamicCommand.instances, arrayWithSize(2));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 2, 1);
		validateCommand(DynamicCommand.instances[1] as DynamicCommand, 1, 1);
		
		MockResultProcessor.dispatchAll();
		sm.dispatchMessage("some message");
		assertThat(DynamicCommand.instances, arrayWithSize(2));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 2, 1, "foo1");
		validateCommand(DynamicCommand.instances[1] as DynamicCommand, 1, 1, "foo1");
	}
	
	[Test]
	public function withErrorHandler () : void {
		var sm:ScopeManager = context.scopeManager;
		assertThat(DynamicCommand.instances, arrayWithSize(0));
		
		sm.dispatchMessage("some message");
		sm.dispatchMessage(new TestEvent("command2", "error", 0));
		assertThat(DynamicCommand.instances, arrayWithSize(1));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 0, 1);
		
		sm.dispatchMessage("some message");
		assertThat(DynamicCommand.instances, arrayWithSize(1));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 1, 1);
		
		sm.dispatchMessage(new TestEvent("command2", "error", 0));
		assertThat(DynamicCommand.instances, arrayWithSize(2));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 1, 1);
		validateCommand(DynamicCommand.instances[1] as DynamicCommand, 0, 1);
		
		sm.dispatchMessage("some message");
		assertThat(DynamicCommand.instances, arrayWithSize(2));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 2, 1);
		validateCommand(DynamicCommand.instances[1] as DynamicCommand, 1, 1);
		
		MockResultProcessor.dispatchAll();
		sm.dispatchMessage("some message");
		assertThat(DynamicCommand.instances, arrayWithSize(2));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 2, 1, "none", "foo1");
		validateCommand(DynamicCommand.instances[1] as DynamicCommand, 1, 1, "none", "foo1");
	}
	
	[Test]
	public function decorators () : void {
		var sm:ScopeManager = context.scopeManager;
		assertThat(DynamicCommand.instances, arrayWithSize(0));
		
		sm.dispatchMessage("some message");
		sm.dispatchMessage(new TestEvent("command3", "foo", 0));
		assertThat(DynamicCommand.instances, arrayWithSize(1));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 0, 1, "none", "none", 9);
		
		sm.dispatchMessage("some message");
		MockResultProcessor.dispatchAll();
		assertThat(DynamicCommand.instances, arrayWithSize(1));
		validateCommand(DynamicCommand.instances[0] as DynamicCommand, 1, 1, "foo1", "none", 9, 1);
	}
	

	private function validateCommand (command:DynamicCommand, handlers:int, commands:int, 
			result:String = "none", error:String = "none", prop:int = 0, destroys:int = 0) : void {
		assertThat(command.handlerCount, equalTo(handlers));
		assertThat(command.commandCount, equalTo(commands));
		assertThat(command.resultValue, equalTo(result));
		assertThat(command.errorValue, equalTo(error));
		assertThat(command.prop, equalTo(prop));
		assertThat(command.destroyCount, equalTo(destroys));
	}

	
	public function get commandContext () : Context {
		throw new AbstractMethodError();
	}
	
	
}
}
