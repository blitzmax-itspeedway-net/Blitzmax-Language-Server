
'   LANGUAGE SERVER MESSAGE HANDLER
'   (c) Copyright Si Dunford, October 2021, All Right Reserved
'
'   https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_hover
'   REQUEST:    textDocument/hover

Rem	
	DESCRIPTION
	
	This handler displays a popup when hovering over a symbol

	FUTURE EXPANSION
	
	Nothing planned
	
	EXAMPLE
	
	{
	  "id": 2,
	  "jsonrpc": "2.0",
	  "method": "textDocument/hover",
	  "params": {
		"position": {
		  "character": 25,
		  "line": 37
		},
		"textDocument": {
		  "uri": "file:///home/si/dev/example/test-message.bmx"
		}
	  }
	}
	
End Rem

' CLIENT HAS REQUESTED DOCUMENT SYMBOLS
Function bls_textDocument_hover:JSON( message:TMessage )

    Local id:String = message.getid()
    'Local params:JSON = message.params
	
	' Get the document
	Local doc_uri:String = message.J.find( "params|textDocument|uri" ).toString()
	Local workspace:TWorkspace = workspaces.get( doc_uri )
	
	Local position:JSON = message.J.find( "params|position" )
	
	'Local document:TTextDocument = TTextDocument( workspace.get( doc_uri ) )

	
Rem
	Local options:Int = 0
	Local contentFormat:JSON[] = client.getCapability( "textDocument|hover|contentFormat" )
	For Local j:JSON = EachIn contentFormat
		Select J.toString()
		Case "markdown"
			options :| CONTENT_MARKDOWN
			logfile.debug( "# HOVER supports Markdown" )
		Case "plaintext"
			options :| CONTENT_PLAINTEXT
			logfile.debug( "# HOVER supports plaintext" )
HERE->
		EndSelect
	Next
End Rem

	Local data:JSON = workspace.cache.getSymbolAt( position )
	logfile.debug( "CREATED DATA" )
	Local response:JSON = Response_OK( id )
		
	response.set( "result", data )

	Return response

End Function
