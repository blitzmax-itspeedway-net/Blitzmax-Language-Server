
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Definition Provider (Added in V0.2)



' Register this component
new TDefinitionProvider()
Type TDefinitionProvider Extends TMessageHandler

	Method New()
		'DebugStop
		lsp.register( self )
		' Register Capabilities
		lsp.capabilities.set( "definitionProvider", "true" )
		'lsp.addHandler( Self, ["textDocument/didOpen", "textDocument/didChange", "textDocument/didClose","textDocument/didSave","textDocument/willSave","textDocument/willSaveWaitUntil"] )
	End Method
	
	'Method Notify( message:String, data:Object, extra:Object )
	'End Method
	
	'Method Signal:Int( event:String, data:Object, extra:Object )
	'End Method
	
	' Called by Worker thread to process a message
	Method run:String( message:TMessage )
		Publish( "info", "TDefinitionProvider received "+message.methd )
		Select message.methd
		'Case "textDocument/didOpen"		; Return didOpen( message )
		'Case "textDocument/didChange"	; Return didChange( message )
		'Case "textDocument/didClose"	; Return didClose( message )
		'Case "textDocument/didSave"		; Return didSave( message )
		Default
			Publish( "error", "## TDefinitionProvider failed to handle "+message.methd )
		End Select
		Return ""
	End Method
	
	'Method didOpen:String( message:TMessage )
		Rem

		end rem

	'	Publish( "log","debug",message.J.stringify() )

	'End Method

End Type
