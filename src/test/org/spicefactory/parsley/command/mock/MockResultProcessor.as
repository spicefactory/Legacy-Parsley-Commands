package org.spicefactory.parsley.command.mock {


/**
 * @author Jens Halm
 */
public class MockResultProcessor {


	private static var callbacks:Array = new Array();
	
	
	public static function getNextCommand () : MockResultCallback {
		return callbacks.shift() as MockResultCallback;
	}
	
	public static function get commandCount () : uint {
		return callbacks.length; 
	}

	public static function dispatchAll () : void {
		for each (var com:MockResultCallback in callbacks) {
			com.dispatchResult();
		}
	}
	
	public static function reset () : void {
		callbacks = new Array();
	}
	
	
	public function execute (result: MockResult, callback: Function): void {
		var c:MockResultCallback = new MockResultCallback(result, callback);
		callbacks.push(c);
	}
	
	
}
}

import org.spicefactory.parsley.command.mock.MockResult;

class MockResultCallback {


	private var result: MockResult;
	private var callback: Function;


	function MockResultCallback (result: MockResult, callback: Function) {
		this.result = result;
		this.callback = callback;
	}
	
	
	public function dispatchResult () : void {
		var value: Object = (result.error) ? new Error(result.value) : result.value;
		callback(value);
	}
	
	
}
