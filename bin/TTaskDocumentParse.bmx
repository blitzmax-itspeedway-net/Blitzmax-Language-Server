
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

' TTaskDocumentParse performs the following actions
' Lexical analysis
' Parsing to AST
' Extracting symbols
' Saving AST to cache
' Saving Symbols To cache

Type TTaskDocumentParse Extends TTask

	Field document:TTextDocument

	Method New( document:TTextDocument, priority:Int = QUEUE_PRIORITY_DOCUMENT_PARSE )
		name = "document{"+document.uri.tostring()+"}"
		Self.priority = priority
		Self.document = document
	End Method

	Method execute()
		Local start:Int, finish:Int
		If document.content = "" ; Return
		
		' Parse the document
		
		logfile.debug( "> Parsing '"+document.uri.tostring()+"'" )
		client.logMessage( "Parsing '"+document.uri.tostring()+"'", EMessageType.info.ordinal() )

		start = MilliSecs()
		document.lexer = New TBlitzMaxLexer( document.content )
		Local parser:TParser = New TBlitzMaxParser( document.lexer )
		document.ast = parser.parse_ast()
		' Parse the AST into a symbol table
		createSymbolTable()
		finish = MilliSecs()
		
		'logfile.debug( "FILE '"+uri.tostring()+"':" )
		'logfile.debug( lexer.reveal() )
		'logfile.debug( parser.reveal() )
		'logfile.debug( ast.reveal() )

		logfile.debug( "> Parsed '"+document.uri.tostring()+"' in "+(finish-start)+"ms" )
		client.logMessage( "Parsed '"+document.uri.tostring()+"' in "+(finish-start)+"ms", EMessageType.info.ordinal() )


		' We don't need to keep stuff if document is closed
		If document.isOpen ; Return
		document.content = ""
		document.lexer = Null
		document.ast = Null
	End Method

	Method createSymbolTable()
		
	End Method
	
End Type