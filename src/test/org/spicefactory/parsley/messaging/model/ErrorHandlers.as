package org.spicefactory.parsley.messaging.model {

import org.spicefactory.parsley.core.messaging.MessageProcessor;
import org.spicefactory.parsley.util.MessageCounter;

/**
 * @author Jens Halm
 */
public class ErrorHandlers extends MessageCounter {

	
	public function allTestEvents (error:Error, processor:MessageProcessor) : void {
		addMessage(processor.message);
		processor.resume();
	}
	
	public function allEvents (error:Error, processor:MessageProcessor) : void {
		addMessage(processor.message);
		processor.resume();
	}
	
	public function event1 (error:Error, processor:MessageProcessor) : void {
		addMessage(processor.message, "test1");
		processor.resume();
	}
	
	public function event2 (error:Error, processor:MessageProcessor) : void {
		addMessage(processor.message, "test2");
		processor.resume();
	}
	

}
}
