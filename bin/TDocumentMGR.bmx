
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Document Manager (Added in V0.2)

Type TDocumentMGR Extends TEventHandler
	Global documents:TMap = New TMap()
	
	' Threads
	
	Field DocThread:TThread
	Field QuitDocThread:Int = True
	Field semaphore:TSemaphore = CreateSemaphore( 0 )
	
	Method New()
		DocThread = CreateThread( DocManagerThread, Self )	' Document Manager
		listen()
		'
		'	REGISTER CAPABILITIES
		
		' Incremental document sync
		lsp.capabilities.set( "textDocumentSync", TextDocumentSyncKind._Incremental )
		' Register for code completion events
		lsp.capabilities.set( "definitionProvider", "true" )
		' Register for definition provide events
		lsp.capabilities.set( "completionProvider|resolveProvider", "true" )
		'
	End Method

	Method Close()
		AtomicSwap( QuitDocThread, False )  ' Inform thread it must exit
		PostSemaphore( semaphore )  		' Wake the thread from it's slumber
        DetachThread( DocThread )
        Publish( "debug", "Document thread closed" )
		unlisten()
	End Method
	
	' Invalidate the document list forcing a re-validation
	Method invalidate()
		PostSemaphore( semaphore )
	End Method
	
	'Method add( uri:String, content:String )
	'	documents.insert( uri, New TDocument( content ) )
	'End Method
	
	Method open:TDocument( textDocument:JSON )
		Local uri:String = textDocument.find( "uri" ).toString()
		'Local languageid:JSON = = textDocument.find( "languageId" )
		'Local version:JSON = textDocument.find( "params|textDocument|version" )	

		Local document:TDocument = TDocument( documents.valueforkey( uri ) )
		If Not document
			Local text:JSON = textDocument.find( "text" )
			document = New TDocument( uri, text.tostring() )
			documents.insert( uri, document )
		End If
		
		Return document
	End Method
	
	' Validate all documents
	Method validate()
		
	End Method

    ' Thread to manage documents
    Function DocManagerThread:Object( data:Object )
        Local manager:TDocumentMGR = TDocumentMGR( data )
        Local quit:Int = False          ' Always got to know when to quit!
		Repeat
			Try
                Publish( "debug", "DocumentMGR: Resting..")
				WaitSemaphore( manager.semaphore )
                Publish( "debug", "DocumentMGR: Awoken.." )
				
				' VALIDATE DOCUMENTS
				manager.validate()
				
            Catch Exception:String 
                'DebugLog( Exception )
                Publish( "log", "CRIT", Exception )
            End Try
		Until CompareAndSwap( manager.QuitDocThread, quit, True )
	End Function
	
	'	V0.3 EVENT HANDLERS
	'	WE MUST RETURN MESSAGE IF WE DO NOT HANDLE IT
	'	RETURN NULL WHEN MESSAGE HANDLED OR ERROR HANDLED
	
	'	Message.Extra contains the original JSON being sent
	'	Message.Params contains the parameters
	
	Method onDidChange:TMessage( message:TMessage )
Publish( "log", "DBG", "TDocumentMGR.onDidChange()" )
		'Return Null
	End Method
	
	Method onDidOpen:TMessage( message:TMessage )
Publish( "log", "DBG", "TDocumentMGR.onDidOpen()" )
		If Not message Or Not message.params
			client.send( Response_Error( ERR_INTERNAL_ERROR, "Incomplete Event" ) )
			Return Null
		End If
		'
		Local params:JSON = message.params
		
		Local uri:String  = params.find( "textDocument|uri" ).tostring()
		'Local languageid:String = params.find( "textDocument|languageId" ).toString()
		'Local version:String = params.find( "textDocument|version" ).toString()

		Local document:TDocument = TDocument( documents.valueforkey( uri ) )
		If Not document
			Local text:String = params.find( "textDocument|text" ).tostring()
			document = New TDocument( uri, text )
			documents.insert( uri, document )
		End If

		' NOTIFICATION: No response required.
		' client.send( Response_ok() )
		
		' Wake up the Document Thread
		PostSemaphore( semaphore )
		'
	End Method
	
	Method onWillSave:TMessage( message:TMessage )
Publish( "log", "DBG", "TDocumentMGR.onWillSave()" )

	End Method
	
	Method onWillSaveWaitUntil:TMessage( message:TMessage )
Publish( "log", "DBG", "TDocumentMGR.onWillSaveWaitUntil()" )

	End Method
	
	Method onDidSave:TMessage( message:TMessage )
Publish( "log", "DBG", "TDocumentMGR.onDidSave()" )

	End Method
	
	Method onDidClose:TMessage( message:TMessage )
Publish( "log", "DBG", "TDocumentMGR.onDidClose()" )

	End Method

	Method onDefinition:TMessage( message:TMessage )
		Publish( "log", "DBG", "TDocumentMGR.onDefinition()" )
		If Not message Or Not message.J
			client.send( Response_Error( ERR_INTERNAL_ERROR, "Null value" ) )
			Return Null
		End If
		logfile.info( "~n"+message.j.Prettify() )
		' We have NOT dealt with it, so return message
		Return message
	End Method
	
	Method onCompletion:TMessage( message:TMessage )
		Publish( "log", "DBG", "TDocumentMGR.onCompletion()" )
		If Not message Or Not message.J
			client.send( Response_Error( ERR_INTERNAL_ERROR, "Null value" ) )
			Return Null
		End If
		logfile.info( "~n"+message.j.Prettify() )
		'
		' Generate response
		Local response:JSON = New JSON()
		Local items:JSON = New JSON( JSON_ARRAY )
		Local item:JSON
		response.set( "id", message.MsgID )
		response.set( "jsonrpc", JSONRPC )
		response.set( "result|isIncomplete", "true" )
		response.set( "result|items", items )
		
		item = New JSON()
		item.set( "label", "Scaremonger" )
		item.set( "kind", CompletionItemKind._Text )
		item.set( "data", 1 )	' INDEX
		items.addlast( item )
		
		item = New JSON()
		item.set( "label", "BlitzMax" )
		item.set( "kind", CompletionItemKind._Text )
		item.set( "data", 2 )	' INDEX
		items.addlast( item )

		' Reply to the client
		client.send( response )
	End Method
	
	'	Provide additional information for item selected in the completion list
	Method onCompletionResolve:TMessage( message:TMessage )
		Publish( "log", "DBG", "TDocumentMGR.onCompletion()" )
		If Not message Or Not message.J Or Not message.params
			client.send( Response_Error( ERR_INTERNAL_ERROR, "Null value" ) )
			Return Null
		End If
		logfile.info( "~n"+message.j.Prettify() )
		
		' Extract requested information
		Local data:Int = message.params.find("data").toint()
		Local inserttextformat:Int = message.params.find("insertTextFormat").toint()
		Local kind:Int = message.params.find("kind").toint()
		Local label:String = message.params.find("label").toString()

		
		' Generate response
		Local response:JSON = New JSON()
		Local items:JSON = New JSON( JSON_ARRAY )
		Local item:JSON
		response.set( "id", message.MsgID )
		response.set( "jsonrpc", JSONRPC )
		response.set( "result|items", items )

		' HERE WE SHOULD LOOK UP THE COMPLETION ITEM USING INDEX OF "data"
		
		If data=1	' SCAREMONGER
				
			item = New JSON()
			item.set( "detail", "Scaremonger details" )
			item.set( "documentation", "He is a very tall geek" )
			items.addlast( item )

		ElseIf data=2	' BLITZMAX

			item = New JSON()
			item.set( "detail", "Blitzmax detail" )
			item.set( "documentation", "Blitzmax documentation" )
			items.addlast( item )

		End If
		
		' Reply to the client
		client.send( response )  
		
		'Return message	' UNHANDLED EVENT  
	End Method
	
	Method onDocumentSymbol:TMessage( message:TMessage )
	Return message
	End Method
	
End Type

Type TDocument
	Field content:String
	Field uri:String
	Field isopen:Int = False
	Field ismodified:Int = False
	
	Method New( uri:String, content:String )
		Self.content = content
		Self.uri = uri
		Self.isopen = True
	End Method

	Method Close()
		isopen = False
	End Method
	
	Method change( range:TRange, rangeLength:Int, rangeText:String )
		
		ismodified = True
		
		If Not range Or (Not range.isValid()) Return
		
		Local start_pos:Int = range.rangeStart.character
		Local start_line:Int = range.rangeStart.line
		Local end_pos:Int = range.rangeEnd.character
		Local end_line:Int = range.rangeEnd.line
		
		'sourcecode = ""
		
'		For Local line:Int = 0 Until lines.length
'			If (line<start_line) Or (line>end_line)
'				content :+ lines[line]+"~r~n"
'				Continue
'			End If
'			If line=start_line content :+ lines[line][..start_pos] + rangeText
'			If line=end_line content :+ lines[line][end_pos..]+"~r~n"
'		Next
		' Trim additional CRLF from end
'		sourcecode = sourcecode[..(sourcecode.length-2)]
		
		' Update self
'		lines = sourcecode.split( "~r~n" )
		
		' -> VERY INEFFICIENT CODE 
		' -> TO BE REVIEWED LATER
'		PoorMansParser()
		' -^	
		
	End Method
	
End Type

Type TRange
	Field rangeStart:TPosition = New TPosition
	Field rangeEnd:TPosition = New TPosition
	Field _valid:Int = False
	
	Method New( range:JSON )
		rangeStart = New TPosition( range.find("start") )
		rangeEnd = New TPosition( range.find("end") )
		If rangeStart And rangeEnd _valid=True
	End Method
		
	Method isValid:Int()
		Return _valid
	End Method
	
End Type

Type TPosition
	Field character:Int
	Field line:Int
	
	Method New( position:JSON )
		character = position.find("character").toInt()
		line = position.find("line").toInt()
	End Method	
End Type
