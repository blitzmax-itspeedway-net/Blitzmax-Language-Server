
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Document Manager (Added in V0.2)

Type TTextDocument_Handler Extends TMessageHandler

	Const TextDocumentSyncKind_None:Int=0
	Const TextDocumentSyncKind_Full:Int=1
	Const TextDocumentSyncKind_Incremental:Int=2

	field documents:TMap = new TMap()

	Method New()
		'DebugStop
		' Register Capabilities
		lsp.capabilities.set( "textDocumentSync", TextDocumentSyncKind_Incremental )
		'DebugLog( lsp.capabilities.stringify() )
		lsp.addHandler( Self, ["textDocument/didOpen", "textDocument/didChange", "textDocument/didClose","textDocument/didSave","textDocument/willSave","textDocument/willSaveWaitUntil"] )
	End Method
	
	'Method Notify( message:String, data:Object, extra:Object )
	'End Method
	
	'Method Signal:Int( event:String, data:Object, extra:Object )
	'End Method
	
	' Called by Worker thread to process a message
	Method run:String( message:TMessage )
		Publish( "info", "TTextDocument_Handler received "+message.methd )
		Select message.methd
		Case "textDocument/didOpen"		; Return didOpen( message )
		Case "textDocument/didChange"	; Return didChange( message )
		Case "textDocument/didClose"	; Return didClose( message )
		Case "textDocument/didSave"		; Return didSave( message )
			Default
			Publish( "error", "## TTextDocument_Handler failed to handle "+message.methd )
		End Select
		Return ""
	End Method
	
	Method didOpen:String( message:TMessage )
		Rem
		{
		"jsonrpc":"2.0",
		"method":"textDocument/didOpen",
		"params":
			{
			"textDocument":
				{
				"languageId":"blitzmax",
				"text":"<CONTENT OF FILE>",
				"uri":"file:///home/si/dev/LSP/handlers/TTextDocument.bmx",
				"version":1
				}
			}
		}
		end rem

		Publish( "log","debug",message.J.stringify() )

		local uriNode:JSON = message.J.find( "params|textDocument|uri" )
		local textNode:JSON = message.J.find( "params|textDocument|text" )
		
		local uri:string = uriNode.toString() 

		local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		if document
			document.setContent( textnode.toString() )
		else
			' New Document
			document = new TTextDocument( textNode.toString() )
		end if

	End Method
	
	Method didChange:String( message:TMessage )
		rem
		{
		"jsonrpc":"2.0",
		"method":"textDocument/didChange",
		"params":
			{
			"contentChanges":
				[
					{
					"range":
						{
						"end":{"character":48,"line":40},
						"start":{"character":48,"line":40}
						},
					"rangeLength":0,
					"text":"~r~n~t~t"
					}
				],
			"textDocument":
				{
				"uri":"file:///home/si/dev/LSP/handlers/TTextDocument.bmx",
				"version":2
				}
			}
		}
		end rem
		Publish( "log","debug",message.J.stringify() )

		local uriNode:JSON = message.J.find( "params|textDocument|uri" )		
		local uri:string = uriNode.toString() 

		local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		if document
			document.change()
		end if

	End Method

	Method didClose:String( message:TMessage )
		rem
		{
		"jsonrpc":"2.0",
		"method":"textDocument/didClose",
		"params":
			{
			"textDocument":
				{
				"uri":"file:///home/si/dev/LSP/handlers/TTextDocument.bmx"
				}
			}
		}
		end rem
		Publish( "log","debug",message.J.stringify() )

		local uriNode:JSON = message.J.find( "params|textDocument|uri" )		
		local uri:string = uriNode.toString() 

		local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		if document
			document.close()
		end if

	End Method

	Method didSave:String( message:TMessage )
		rem
		{
		"jsonrpc":"2.0",
		"method":"textDocument/didSave",
		"params":
			{
			"textDocument":
				{
				"uri":"file:///home/si/dev/LSP/handlers/TTextDocument.bmx",
				"version":3
				}
			}
		}
		end rem
		Publish( "log","debug",message.J.stringify() )

		local uriNode:JSON = message.J.find( "params|textDocument|uri" )		
		local uri:string = uriNode.toString() 

		local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		if document
			document.save()
		end if

	End Method

End Type

Type TTextDocument
	Field content:String		' Document text
	field isopen:int = False
	Field ismodified:int = False

	Method new( text:string )
		content = text
		isopen = True
		ismodified = False
	End Method

	Method setContent( text:string )
		content = text
		ismodified = False
	End Method

	Method change()
		ismodified = True
	End Method

	Method close()
		isopen = False
	End Method

	Method save()
	End Method

end Type