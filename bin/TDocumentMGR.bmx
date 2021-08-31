
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Document Manager (Added in V0.2)

Global documents:TDocumentMGR = New TDocumentMGR()

Type TDocumentMGR
	Global documents:TMap = New TMap()
	
	' Threads
	
	Field DocThread:TThread
	Field QuitDocThread:Int = True
	Field semaphore:TSemaphore = CreateSemaphore( 0 )
	
	Method New()
		DocThread = CreateThread( DocManagerThread, Self )	' Document Manager
	End Method

	Method Close()
		AtomicSwap( QuitDocThread, False )  ' Inform thread it must exit
		PostSemaphore( semaphore )  		' Wake the thread from it's slumber
        DetachThread( DocThread )
        Publish( "debug", "Document thread closed" )
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
