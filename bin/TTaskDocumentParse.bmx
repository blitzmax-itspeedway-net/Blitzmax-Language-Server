
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
			
			logfile.debug( "> Parsing '"+document.uri.tostring()+"'" )
			client.logMessage( "Parsing '"+document.uri.tostring()+"'", EMessageType.info.ordinal() )

			start = MilliSecs()
			document.lexer = New TBlitzMaxLexer( document.content )
			logfile.debug( "TTaskDocumentParse: Lexer initialised" )
			Local parser:TParser = New TBlitzMaxParser( document.lexer )
			logfile.debug( "TTaskDocumentParse: Parser initialised" )
			document.ast = parser.parse_ast()
			logfile.debug( "TTaskDocumentParse: Document parsed" )

			' Parse the AST into a symbol table
			workspace.cache.addSymbols( document.uri, New TSymbolTable( document.ast ) )
			logfile.debug( "TTaskDocumentParse: Symbols added" )
			
			finish = MilliSecs()
			
			'logfile.debug( "FILE '"+uri.tostring()+"':" )
			'logfile.debug( lexer.reveal() )
			'logfile.debug( parser.reveal() )
			'logfile.debug( ast.reveal() )

			logfile.debug( "TTaskDocumentParse: Parsed '"+document.uri.tostring()+"' in "+(finish-start)+"ms" )
			client.logMessage( "Parsed '"+document.uri.tostring()+"' in "+(finish-start)+"ms", EMessageType.info.ordinal() )


			' We don't need to keep stuff if document is closed
			If document.isOpen ; Return
			document.content = ""
			document.lexer = Null
			document.ast = Null
		Catch e:String
			logfile.critical( "TTaskDocumentParse.launch() Failed: "+e )
		EndTry
	End Method
	
End Type