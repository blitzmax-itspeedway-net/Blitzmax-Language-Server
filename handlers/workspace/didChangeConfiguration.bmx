
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	workspace/didChangeConfiguration

'	THIS DOES NOT WORK!

' Register this component
DebugLog( "TdidChangeConfiguration" )
Publish( "log", "DEBG", "Initialise TdidChangeConfiguration()" )
New TdidChangeConfiguration()

' Message Handler
Type TdidChangeConfiguration Extends TMessageHandler

'	Const TextDocumentSyncKind_None:Int=0
'	Const TextDocumentSyncKind_Full:Int=1
'	Const TextDocumentSyncKind_Incremental:Int=2

'	Field documents:TMap = New TMap()

	Method New()
		Publish( "log", "DEBG", "TdidChangeConfiguration.new()" )

		' Register Capabilities
		' NONE

		' Register Message Handler

Publish( "log", "DEBG", "workspace/didChangeConfiguration "+lsp.capabilities.stringify() )

		' "DID" Handlers
		lsp.addHandler( Self, ["workspace/didChangeConfiguration"] )
	End Method
	
	'Method Notify( message:String, data:Object, extra:Object )
	'End Method
	
	'Method Signal:Int( event:String, data:Object, extra:Object )
	'End Method
	
	' Called by Worker thread to process a message
	Method run:String( message:TMessage )
		Publish( "info", "TdidChangeConfiguration received "+message.methd )
		Select message.methd
		Case "workspace/didChangeConfiguration"		; Return didChangeConfiguration( message )

		Default
			Publish( "error", "## TdidChangeConfiguration failed to handle "+message.methd )
		End Select
		Return ""
	End Method
	
	Method didChangeConfiguration:String( message:TMessage )
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

'		Publish( "log","debug",message.J.stringify() )

'		Local uriNode:JSON = message.J.find( "params|textDocument|uri" )
'		Local textNode:JSON = message.J.find( "params|textDocument|text" )
		
'		Local uri:String = uriNode.toString() 

'		Local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
'		If document
'			document.setContent( textnode.toString() )
'		Else
'			' New Document
'			document = New TTextDocument( textNode.toString() )
'		End If

	End Method
	
