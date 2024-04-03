
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

' 	TTaskDocumentParse performs the following actions
' 		Lexical analysis
' 		Parsing to AST
' 		Extracting symbols
' 		Saving AST to cache
' 		Saving Symbols To cache

Type TTaskDocumentParse Extends TTask

	Field document:TTextDocument
	Field workspace:TWorkspace = Null		' The workspace we are updating
	
	Method New( document:TTextDocument, workspace:TWorkspace, priority:Int = QUEUE_PRIORITY_DOCUMENT_PARSE )
		Super.New( BLOCKING )
		name = "document{"+document.uri.tostring()+"}"
		
		Self.priority = priority
		Self.document = document
		Self.workspace = workspace
		
		' Request a work-done token
		'If client.has( WHAT SHOULD THIS BE? "workspace|symbol|workDone" )
		' local workdone:TTask = new TRequestTask( TClient.progress_register:String() )
		' Need to register a request so we receive a reply
		'End If
		
	End Method

	Method launch()
		Local start:Int, finish:Int
		If document.content = "" ; Return
		
		Try
			' Parse the document
			
			Trace.debug( "> Parsing '"+document.uri.tostring()+"'" )
			client.logMessage( "Parsing '"+document.uri.tostring()+"'", EMessageType.info.ordinal() )

			start = MilliSecs()
			document.lexer = New TBlitzMaxLexer( document.content )
			Trace.debug( "TTaskDocumentParse: Lexer initialised" )
			Local parser:TParser = New TBlitzMaxParser( document.lexer )
			Trace.debug( "TTaskDocumentParse: Parser initialised" )
			document.ast = parser.parse_ast()
			Trace.debug( "TTaskDocumentParse: Document parsed" )

			' Parse the AST into a symbol table
			workspace.cache.addSymbols( document.uri, New TSymbolTable( document.ast ) )
			Trace.debug( "TTaskDocumentParse: Symbols added" )
			
			finish = MilliSecs()
			
			'Trace.debug( "FILE '"+uri.tostring()+"':" )
			'Trace.debug( lexer.reveal() )
			'Trace.debug( parser.reveal() )
			'Trace.debug( ast.reveal() )

			Trace.debug( "TTaskDocumentParse: Parsed '"+document.uri.tostring()+"' in "+(finish-start)+"ms" )
			client.logMessage( "Parsed '"+document.uri.tostring()+"' in "+(finish-start)+"ms", EMessageType.info.ordinal() )


			' We don't need to keep stuff if document is closed
			If document.isOpen ; Return
			document.content = ""
			document.lexer = Null
			document.ast = Null
		Catch e:String
			Trace.critical( "TTaskDocumentParse.launch() Failed: "+e )
		EndTry
	End Method
	
End Type