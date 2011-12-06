package {

import org.spicefactory.parsley.command.OverrideCommandResultTest;
import org.spicefactory.parsley.command.DynamicCommandScopeAndOrderTest;
import org.spicefactory.parsley.command.CommandMetadataTagTest;
import org.spicefactory.parsley.command.CommandMxmlTagTest;
import org.spicefactory.parsley.command.CommandXmlTagTest;
import org.spicefactory.parsley.command.DynamicCommandMxmlTagTest;
import org.spicefactory.parsley.command.DynamicCommandXmlTagTest;

[Suite]
[RunWith("org.flexunit.runners.Suite")]
public class MainSuite {
	
	
	public var commandMetadata:CommandMetadataTagTest;
	public var commandMxml:CommandMxmlTagTest;
	public var commandXml:CommandXmlTagTest;

	public var dynComMxml:DynamicCommandMxmlTagTest;
	public var dynComXml:DynamicCommandXmlTagTest;
	
	public var scopeAndOrder:DynamicCommandScopeAndOrderTest;
	public var overrideResult:OverrideCommandResultTest;
	
	
}
}
