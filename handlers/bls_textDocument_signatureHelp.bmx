
'   LANGUAGE SERVER MESSAGE HANDLER
'   (c) Copyright Si Dunford, October 2021, All Right Reserved
'
'   https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_signatureHelp
'   REQUEST:    textDocument/signatureHelp

Rem	
	DESCRIPTION
	
	This handler displays signature information for Functions and Methods

	FUTURE EXPANSION
	
	Nothing planned
	
	EXAMPLE
	
	{
	  "id": 7,
	  "jsonrpc": "2.0",
	  "method": "textDocument/signatureHelp",
	  "params": {
		"context": {
		  "isRetrigger": false,
		  "triggerCharacter": "(",
		  "triggerKind": 2
		},
		"position": {
		  "character": 11,
		  "line": 4
		},
		"textDocument": {
		  "uri": "file:///home/si/dev/example/crashes.bmx"
		}
	  }
	}

	
End Rem

' CLIENT HAS REQUESTED DOCUMENT SYMBOLS
Function bls_textDocument_signatureHelp:JSON( message:TMessage )

    Local id:String = message.getid()
    'Local params:JSON = message.params
	
	' Get the document
	Local doc_uri:String = message.J.find( "params|textDocument|uri" ).toString()
	Local workspace:TWorkspace = workspaces.get( doc_uri )
	
	Local position:TPosition = New TPosition( message.J.find( "params|position" ))

	' Retrieve the document AST
	Local document:TTextDocument = TTextDocument( workspace.get( doc_uri ) )

	' Can only work with FULL TEXT DOCUMENTS at present
	' Later we may be able to load an AST from file

	If Not document Or Not document.ast Or Not document.lexer
'		logfile.debug( "# NOT A FULL TEXT DOCUMENT" )
		Return Response_OK( id )		' This is "result":null by default
	End If
		
	Local token:TToken = document.lexer.find( position.line+1, position.character-1 ) ' -1 to get NAME
	
'	For Local t:TToken = EachIn document.lexer.tokens
'		logfile.debug( t.reveal() )
'		If position.line+1 = t.line And position.character-1 >= t.pos And position.character-1 <= (t.pos+Len(t.value))
'			logfile.debug( "* FOUND" )
'			token = t
'			Exit
'		ElseIf t.line > position.line+1
'			logfile.debug( "* SEARCH STOPPED" )
'			' Stop searching if we have passed the line number
'			Exit
'		End If
'	Next
	
	' Did we find a suitable token?
	If Not token 'Or Not token.in( TK_
		logfile.debug( "***** TOKEN IS NULL *****" )
		Return Response_OK( id )		' This is "result":null by default
	End If
	logfile.debug( "** TOKEN: "+token.reveal() )

	' Lookup signature in databases
	Local data:JSON = New JSON( JSON_Array )
	Local sym_workspace:JSON[] = workspace.cache.getSymbols( token.value )
	Local sym_module:JSON[] = modules.getSymbols( token.value )
				
	' Response: SignatureHelp

	Local response:JSON = Response_OK( id )
	Local result:JSON = New JSON()
	
	If sym_workspace.length=0 And sym_module.length=0
		result.set( "signatures", "null" )
		'result.set( "activeSignature", "0" )
		'result.set( "activeParameter", "0" )
	Else
	Rem
	{
	  "id": "2",
	  "jsonrpc": "2.0",
	  "result": {
		"activeParameter": "0",
		"activeSignature": "0",
		"signatures": [
		  {
			"activeParameter": 0,
			"documentation": "DOCUMENTATION",
			"label": "WORKSPACE-LABEL",
			"parameters": ""
		  }
		]
	  }
	}
EndRem
		Local data:JSON = New JSON( JSON_Array )
		For Local symbol:JSON = EachIn sym_workspace
			logfile.debug( symbol.stringify() )
			Local item:JSON = New JSON()
			item.set( "label", symbol.find("definition").toString() )
			'item.set( "documentation", "DOCUMENTATION" )
			'item.set( "parameters", [] )
			'item.set( "activeParameter", 0 )
			data.addlast( item )
		Next
		For Local symbol:JSON = EachIn sym_module
			Local item:JSON = New JSON()
			item.set( "label", symbol.find("definition").toString() )
			'item.set( "documentation", "DOCUMENTATION" )
			'item.set( "parameters", [] )
			'item.set( "activeParameter", 0 )
			data.addlast( item )
		Next
		' Move symbol information into response
		result.set( "signatures", data )
		'result.set( "activeSignature", "0" )
		'result.set( "activeParameter", "0" )
	EndIf
	
	response.set( "result", result )
Rem	
	' Create a dummy token
	Local data:JSON = New JSON()
	data.set( "contents|kind", "markdown" )
	'data.set( "contents|value", token.value )
	data.set( "range|start|line", token.line-1 )
	data.set( "range|start|character", token.pos-1 )
	data.set( "range|end|line", token.line-1 )
	data.set( "range|end|character", token.pos + Len(token.value)-2 )
	
	logfile.debug( "***** SIGNATURE IS~n"+data.prettify() )
EndRem
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

Rem
	Local symbols:JSON[] = workspace.cache.getSymbols( token.value )
	Local content:String = token.reveal()+"~n"
	For Local symbol:JSON = EachIn symbols
		content :+ symbol.Stringify()+"~n"
	Next
	data.set( "contents|value", content )
	
'	Local data:JSON = workspace.cache.getSymbolAt( position )
	logfile.debug( "CREATED DATA" )


	Local response:JSON = Response_OK( id )
		
	response.set( "result", data )
EndRem
	logfile.debug( "RESPONSE:~n"+response.prettify() )

	Return response


End Function
