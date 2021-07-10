
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Document Mananger

Type TTextDocument Extends TMessageHandler

	Method New()
		' Register Capabilities
		lsp.addCapability( Self, "textDocumentSync", ["textDocument/didOpen", "textDocument/didChange", "textDocument/didClose"] )
	End Method
	
	'Method Notify( message:String, data:Object, extra:Object )
	'End Method
	
	'Method Signal:Int( event:String, data:Object, extra:Object )
	'End Method
	
	' Called by Worker thread to process a message
	Method run:String( message:TMessage )
		Publish( "info", "TTextDocument received "+message.methd )
		Select message.methd
		Case "textDocument/didOpen"		; Return didOpen( message )
		Case "textDocument/didChange"	; Return didChange( message )
		Case "textDocument/didClose"	; Return didClose( message )
		End Select
		Return ""
	End Method
	
	Method didOpen:String( message:TMessage )
	End Method
	
	Method didChange:String( message:TMessage )
	End Method

	Method didClose:String( message:TMessage )
	End Method

End Type