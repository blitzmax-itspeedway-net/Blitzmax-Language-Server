
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Document Manager (Added in V0.2)

Type TTextDocument Extends TMessageHandler

	Const TextDocumentSyncKind_None:Int=0
	Const TextDocumentSyncKind_Full:Int=1
	Const TextDocumentSyncKind_Incremental:Int=2

	Method New()
		'DebugStop
		' Register Capabilities
		lsp.capabilities.set( "textDocumentSync", TextDocumentSyncKind_Incremental )
		'DebugLog( lsp.capabilities.stringify() )
		lsp.addHandler( Self, ["textDocument/didOpen", "textDocument/didChange", "textDocument/didClose"] )
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
		Default
			Publish( "error", "TTextDocument failed to handle "+message.methd )
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