
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
	
	Local position:TPosition = New TPosition( message.J.find( "params|position" ))

	' Retrieve the document AST
	Local document:TTextDocument = TTextDocument( workspace.get( doc_uri ) )

	' Can only work with FULL TEXT DOCUMENTS at present
	' Later we may be able to load an AST from file

	If Not document Or Not document.ast
'		Trace.debug( "# NOT A FULL TEXT DOCUMENT" )
		Return Response_OK( id )		' This is "result":null by default
	End If
	
	' Find the token at the cursor

	If document.lexer = Null
		Trace.debug( "***** LEXER IS NULL *****" )
	Else
		Trace.debug( "***** LEXER IS OK *****" )
	End If
	
	Local token:TToken
	
	' MOVE THIS INTO LEXER: at( position )
	
	For Local t:TToken = EachIn document.lexer.tokens
		If position.line = t.line-1 And position.character >= t.pos-1 And position.character-1 < (t.pos+Len(t.value)-2)
			token = t
			Exit
		ElseIf t.line-1 > position.line
			Trace.debug( "* SEARCH STOPPED AT "+t.reveal() )
			' Stop searching if we have passed the line number
			Exit
		End If
	Next
	
	' Did we find a suitable token?
	If Not token 'Or Not token.in( TK_
		Trace.debug( "***** TOKEN IS NULL *****" )
		Return Response_OK( id )		' This is "result":null by default
	End If
	
	' Create a dummy token
'	Local data:JSON = New JSON()
'	data.set( "contents|kind", "markdown" )
'	'data.set( "contents|value", token.value )
'	data.set( "range|start|line", token.line-1 )
'	data.set( "range|start|character", token.pos-1 )
'	data.set( "range|end|line", token.line-1 )
'	data.set( "range|end|character", token.pos + Len(token.value)-2 )
	
Rem
	Local options:Int = 0
	Local contentFormat:JSON[] = client.getCapability( "textDocument|hover|contentFormat" )
	For Local j:JSON = EachIn contentFormat
		Select J.toString()
		Case "markdown"
			options :| CONTENT_MARKDOWN
			Trace.debug( "# HOVER supports Markdown" )
		Case "plaintext"
			options :| CONTENT_PLAINTEXT
			Trace.debug( "# HOVER supports plaintext" )
HERE->
		EndSelect
	Next
End Rem

	Local symbols:JSON[] = workspace.cache.getSymbols( token.value )
	Local modsym:JSON[] = modules.getSymbols( token.value )
		
	Local multiple:Int = ( symbols.length > 1 )
	
	'	Create Markdown content
	Local content:String 
	'content :+ token.reveal()+"~n~n"	' DEBUG...
	If symbols.length = 0
		content :+ token.reveal()+"~n"
	End If
	
	content :+ "~n**Modules**~n"
	For Local i:Int = 0 Until modsym.length
		Local symbol:JSON = modsym[i]
		content :+ "~n"+i+". "+symbol.Stringify()+"~n"		' DEBUG...
	Next
	
	content :+ "~n**Workspace**~n"
	For Local i:Int = 0 Until symbols.length
	'For Local symbol:JSON = EachIn symbols
		Local symbol:JSON = symbols[i]
		'content :+ "~n"+i+". "+symbol.Stringify()+"~n"		' DEBUG...
		
		' Show the definition and description if there is one:
		content :+ "~n```"+MARKDOWN_LANGUAGE+"~n"
		content :+ symbol.find("definition").tostring() + "~n"
		content :+ "```~n"

		Local description:String = symbol.find("description").tostring()
		If description <> ""
			content :+ "~n"+description + "~n"
		End If
		
		' Show the file
		content :+ "~n_"+symbol.find("location|uri").tostring()
		content :+ ", line "+symbol.find("location|range|start|line").tostring() +"_~n~n"
		
		' Add a horizontal line between results
		If multiple And i< symbols.length
			content :+ "---~n"
		End If
		
	Next

	' CREATE RESULTS
	
	Local data:JSON = New JSON()	
	data.set( "contents|kind", "markdown" )
	data.set( "contents|value", content )
	
	' Highlight in document	
	data.set( "range|start|line", token.line-1 )
	data.set( "range|start|character", token.pos-1 )
	data.set( "range|end|line", token.line-1 )
	data.set( "range|end|character", token.pos + Len(token.value)-2 )
	
'	Local data:JSON = workspace.cache.getSymbolAt( position )
	Trace.debug( "CREATED DATA~n"+data.prettify() )


	Local response:JSON = Response_OK( id )
		
	response.set( "result", data )

	Return response

End Function
