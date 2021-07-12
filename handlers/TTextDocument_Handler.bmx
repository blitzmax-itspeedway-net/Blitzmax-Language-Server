
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Document Manager (Added in V0.2)

'Definition MUST Return "undefined" by Default.

' Register this component
DebugLog( "TTextDocument_Handler" )
Publish( "log", "DEBG", "Initialise TTextDocument_Handler()" )
New TTextDocument_Handler()
Type TTextDocument_Handler Extends TMessageHandler

	Const TextDocumentSyncKind_None:Int=0
	Const TextDocumentSyncKind_Full:Int=1
	Const TextDocumentSyncKind_Incremental:Int=2

	Field documents:TMap = New TMap()

	Method New()
		Publish( "log", "DEBG", "TTextDocument_Handler.new()" )
		'DebugStop
		'lsp.register( Self )
		' Register Capabilities
		lsp.capabilities.set( "textDocumentSync", TextDocumentSyncKind_Incremental )
		lsp.capabilities.set( "definitionProvider", "true" )
		
'DebugStop		
'DebugLog( lsp.capabilities.stringify() )
Publish( "log", "DEBG", "TextDocument:Capabilities: "+lsp.capabilities.stringify() )

		'DebugLog( lsp.capabilities.stringify() )
		' "DID" Handlers
		lsp.addHandler( Self, ["textDocument/didOpen", "textDocument/didChange", "textDocument/didClose","textDocument/didSave"] )
		' "WILL" Handlers
		lsp.addHandler( Self, ["textDocument/willSave","textDocument/willSaveWaitUntil"] )
		' "WILL" Handlers
		lsp.addHandler( Self, ["textDocument/definition","textDocument/typeDefinition"] )
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

		Case "textDocument/definition"		; Return definition( message )
		Case "textDocument/typeDefinition"	; Return typeDefinition( message )

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

		Local uriNode:JSON = message.J.find( "params|textDocument|uri" )
		Local textNode:JSON = message.J.find( "params|textDocument|text" )
		
		Local uri:String = uriNode.toString() 

		Local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		If document
			document.setContent( textnode.toString() )
		Else
			' New Document
			document = New TTextDocument( textNode.toString() )
		End If

	End Method
	
	Method didChange:String( message:TMessage )
		Rem
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

		Local uriNode:JSON = message.J.find( "params|textDocument|uri" )		
		Local uri:String = uriNode.toString() 

		Local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		If document
			document.change()
		End If

	End Method

	Method didClose:String( message:TMessage )
		Rem
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

		Local uriNode:JSON = message.J.find( "params|textDocument|uri" )		
		Local uri:String = uriNode.toString() 

		Local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		If document
			document.Close()
		End If

	End Method

	Method didSave:String( message:TMessage )
		Rem
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

		Local uriNode:JSON = message.J.find( "params|textDocument|uri" )		
		Local uri:String = uriNode.toString() 

		Local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		If document
			document.save()
		End If

	End Method

	Method definition:String( message:TMessage )
		Rem

		end rem
		Publish( "log","debug",message.J.stringify() )
		
		' Default response is "null"
        Local response:JSON = New JSON()
        response.set( "id", message.id )
        response.set( "jsonrpc", JSONRPC )
        response.set( "result", "null" )

        Return response.stringify()
	End Method

	Method typeDefinition:String( message:TMessage )
		Rem

		end rem
		Publish( "log","debug",message.J.stringify() )

		' Default response is "null"
        Local response:JSON = New JSON()
        response.set( "id", message.id )
        response.set( "jsonrpc", JSONRPC )
        response.set( "result", "null" )

        Return response.stringify()
	End Method
	
End Type

Type TTextDocument
	Field content:String		' Document text
	Field isopen:Int = False
	Field ismodified:Int = False

	Method New( text:String )
		content = text
		isopen = True
		ismodified = False
	End Method

	Method setContent( text:String )
		content = text
		ismodified = False
	End Method

	Method change()
		ismodified = True
	End Method

	Method Close()
		isopen = False
	End Method

	Method save()
	End Method

End Type