package org.spicefactory.parsley.command {

import org.hamcrest.assertThat;
import org.hamcrest.object.equalTo;
import org.spicefactory.lib.command.result.ResultProcessors;
import org.spicefactory.parsley.command.config.OverrideResultMxmlConfig;
import org.spicefactory.parsley.command.mock.MockResult;
import org.spicefactory.parsley.command.mock.MockResultProcessor;
import org.spicefactory.parsley.command.model.CommandExecutors;
import org.spicefactory.parsley.command.model.CommandExecutorsMetadata;
import org.spicefactory.parsley.command.model.OverrideCommandResultModel;
import org.spicefactory.parsley.command.model.SimpleResultObserver;
import org.spicefactory.parsley.context.ContextBuilder;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.flex.FlexConfig;
import org.spicefactory.parsley.messaging.messages.TestEvent;

/**
 * @author Jens Halm
 */
public class OverrideCommandResultTest {
	
	
	[BeforeClass]
	public static function registerMockCommandFactory () : void {
		if (!ResultProcessors.forResultType(MockResult).exists) {
			ResultProcessors.forResultType(MockResult).processorType(MockResultProcessor);
		}
	}
	
	
	[Test]
	public function overrideResultInSeparateObserver () : void {
		MockResultProcessor.reset();
		
		var executors:CommandExecutors = new CommandExecutorsMetadata();
		var model:OverrideCommandResultModel = new OverrideCommandResultModel();
		var context:Context = ContextBuilder.newBuilder().object(executors).object(model).build();
		context.scopeManager.dispatchMessage(new TestEvent(TestEvent.TEST2, "foo", 0));
		MockResultProcessor.dispatchAll();
		assertThat(model.invocationOrder, equalTo("ABC"));
	}
	
	[Test]
	public function overrideResultInCommand () : void {
		MockResultProcessor.reset();
		
		var observer:SimpleResultObserver = new SimpleResultObserver();
		var context:Context = ContextBuilder
			.newBuilder()
			.config(FlexConfig.forClass(OverrideResultMxmlConfig))
			.object(observer)
			.build();
		context.scopeManager.dispatchMessage(new TestEvent(TestEvent.TEST1, "foo", 0));
		MockResultProcessor.dispatchAll();
		assertThat(observer.lastResult, equalTo("foo:modified"));
	}
	
	
}
}
