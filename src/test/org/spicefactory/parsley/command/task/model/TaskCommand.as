package org.spicefactory.parsley.command.task.model {


/**
 * @author Jens Halm
 */
public class TaskCommand {
	
	
	public static var lastTask:MockResultTask;
	public static var resultString:String;
	public static var resultCounter:int = 0;
	
	/*
	
	public function execute(event:TestEvent) : Task {
		lastTask = new MockResultTask(event.stringProp, true);
		return lastTask;
	}
	 * 
	 */
	
	public function result (result:String) : void {
		resultString = result;
		resultCounter++;
	}
	
	
}
}
