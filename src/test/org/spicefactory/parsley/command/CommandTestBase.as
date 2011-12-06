package org.spicefactory.parsley.command {

import org.spicefactory.parsley.core.command.ObservableCommand;
import org.flexunit.assertThat;
import org.hamcrest.collection.array;
import org.hamcrest.collection.arrayWithSize;
import org.hamcrest.core.allOf;
import org.hamcrest.core.isA;
import org.hamcrest.object.equalTo;
import org.hamcrest.object.hasProperty;
import org.spicefactory.lib.command.result.ResultProcessors;
import org.spicefactory.lib.errors.AbstractMethodError;
import org.spicefactory.parsley.command.mock.MockResult;
import org.spicefactory.parsley.command.mock.MockResultProcessor;
import org.spicefactory.parsley.command.model.CommandExecutors;
import org.spicefactory.parsley.command.model.CommandObservers;
import org.spicefactory.parsley.command.model.CommandStatusFlags;
import org.spicefactory.parsley.core.command.CommandManager;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.core.scope.ScopeManager;
import org.spicefactory.parsley.core.scope.ScopeName;
import org.spicefactory.parsley.messaging.messages.TestEvent;
import org.spicefactory.parsley.messaging.model.EventSource;

import flash.events.Event;

/**
 * @author Jens Halm
 */
public class CommandTestBase {
	
	
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
		context = commandContext;
	}
	
	
	[Test]
	public function commandResult () : void {
		context.getObjectByType(CommandExecutors) as EventSource;
		var observers:CommandObservers = context.getObjectByType(CommandObservers) as CommandObservers;
		var sm:ScopeManager = context.scopeManager;
		sm.dispatchMessage(new TestEvent(TestEvent.TEST1, "foo1", 7));
		sm.dispatchMessage(new TestEvent(TestEvent.TEST2, "foo2", 9));
		sm.dispatchMessage(new Event("foo"));
		MockResultProcessor.dispatchAll();
		
		assertThat(observers.noParamCalled, equalTo(1));
		assertThat(observers.oneParamResult, array("foo1"));
		assertThat(observers.twoParamsResult, array("foo1"));
		assertThat(observers.twoParamsMessage, array(allOf(isA(TestEvent), hasProperty("intProp", 7))));
		assertThat(observers.errorResult, array("fault"));
		assertThat(observers.errorMessage, array(allOf(isA(TestEvent), hasProperty("intProp", 7))));
		assertThat(observers.completeInvoked, equalTo(1));
	}
	
	[Test]
	public function commandStatus () : void {
		context.getObjectByType(CommandExecutors) as EventSource;
		var flags:CommandStatusFlags = context.getObjectByType(CommandStatusFlags) as CommandStatusFlags;
		var sm:ScopeManager = context.scopeManager;
		var cm:CommandManager = sm.getScope(ScopeName.GLOBAL).commandManager;
		
		validateFlags(flags, false, false, false);
		validateManager(cm, 0, 0, 0);
		
		sm.dispatchMessage(new TestEvent(TestEvent.TEST1, "foo1", 7));
		validateFlags(flags, true, true, false);
		validateManager(cm, 2, 2, 0);
		
		sm.dispatchMessage(new TestEvent(TestEvent.TEST2, "foo2", 9));
		validateFlags(flags, true, true, true);
		validateManager(cm, 3, 2, 1);
		
		sm.dispatchMessage(new Event("foo"));
		validateFlags(flags, true, true, true);
		validateManager(cm, 3, 2, 1);

		MockResultProcessor.getNextCommand().dispatchResult();
		validateFlags(flags, true, true, true);
		validateManager(cm, 2, 1, 1);

		MockResultProcessor.getNextCommand().dispatchResult();
		validateFlags(flags, true, false, true);
		validateManager(cm, 1, 0, 1);

		MockResultProcessor.getNextCommand().dispatchResult();
		validateFlags(flags, false, false, false);
		validateManager(cm, 0, 0, 0);
		
	}
	
	[Test]
	public function statusFlagInitValue () : void {
		context.getObjectByType(CommandExecutors) as EventSource;
		var sm:ScopeManager = context.scopeManager;
		var cm:CommandManager = sm.getScope(ScopeName.GLOBAL).commandManager;
		
		validateManager(cm, 0, 0, 0);
		
		sm.dispatchMessage(new TestEvent(TestEvent.TEST1, "foo1", 7));
		var flags:CommandStatusFlags = context.getObjectByType(CommandStatusFlags) as CommandStatusFlags;
		validateFlags(flags, true, true, false);
		validateManager(cm, 2, 2, 0);
		MockResultProcessor.dispatchAll();
		validateFlags(flags, false, false, false);
		validateManager(cm, 0, 0, 0);
	}
	
	
	private function validateFlags (flags:CommandStatusFlags, both:Boolean, flag1:Boolean, flag2:Boolean) : void {
		assertThat(flags.flag1and2, equalTo(both));
		assertThat(flags.flag1, equalTo(flag1));
		assertThat(flags.flag2, equalTo(flag2));
	}
	
	private function validateManager (cm:CommandManager, both:uint, flag1:uint, flag2:uint) : void {
		assertThat(getFilteredActiveCommands(cm, TestEvent), arrayWithSize(both));
		assertThat(getFilteredActiveCommands(cm, TestEvent, "test1"), arrayWithSize(flag1));
		assertThat(getFilteredActiveCommands(cm, TestEvent, "test2"), arrayWithSize(flag2));
	}
	
	private function getFilteredActiveCommands (cm:CommandManager, type: Class, selector: * = undefined): Array {
		var commands: Array = cm.getActiveCommandsByTrigger(type, selector);
		var result: Array = [];
		for each (var com: ObservableCommand in commands) {
			if (com.command is CommandExecutors) result.push(com);
		}
		return result;
	}

	
	
	public function get commandContext () : Context {
		throw new AbstractMethodError();
	}
	
	
}
}
