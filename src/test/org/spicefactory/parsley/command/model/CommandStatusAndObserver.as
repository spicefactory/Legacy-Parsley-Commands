package org.spicefactory.parsley.command.model {
import org.spicefactory.parsley.command.mock.MockResult;
import org.spicefactory.parsley.core.messaging.MessageProcessor;
import org.spicefactory.parsley.messaging.messages.TestEvent;

/**
 * @author Jens Halm
 */
public class CommandStatusAndObserver {
	
	
	[CommandStatus(type="org.spicefactory.parsley.messaging.messages.TestEvent")]
	public var status:Boolean;
	
	[CommandComplete]
	public function complete (event:TestEvent, processor:MessageProcessor) : void {
		processor.cancel();
	}
	
	[Command]
	public function execute () : MockResult {
		return new MockResult("foo");
	}
	
	
}
}
