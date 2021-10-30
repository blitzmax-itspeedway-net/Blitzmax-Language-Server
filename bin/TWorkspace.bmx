
'	WORKSPACE MANAGER
'	(c) Copyright Si Dunford, October 2021, All Rights Reserved

Type TWorkspaces Extends TEventHandler

	Global list:TMap = New TMap()
	
	' Add a Workspace
	Method add( uri:TURI, workspace:TWorkspace )
		list[ uri.toString() ] = workspace
		
		'logfile.debug( "Workspaces now contain:" )
		'For Local key:String = EachIn list.keys()
		'	logfile.debug( key )
		'Next
	End Method
	
	' Remove a Workspace
	Method remove( uri:TURI )
		list.remove( uri.toString() )
	End Method

	' Find a workspace for a file uri
	Method get:TWorkspace( doc_uri:String )
		Local uri:TURI = New TURI( doc_uri )
		If uri ; Return get( uri )
	End Method
	
	Method get:TWorkspace( uri:TURI )
		If Not uri; Return Null
		
		'Local uri:TURI = TURI.file( file_uri )
		
		
		' Extract filepath from uri path (Drop the filename)
		'logfile.debug( "FOLDER IS:" + ExtractDir( uri.path ) )
		Local path:String = uri.folder()
		'logfile.debug( "Finding URI: "+ uri.toString()+"~n  SCHEME:"+uri.scheme+"~n  AUTHORITY:"+uri.authority+"~n  PATH: "+path )
		
		' Match workspaces
		For Local key:String = EachIn list.keys()
			Local workspace:TWorkspace = TWorkspace( list[key] )
			'logfile.debug( "Comparing: "+ workspace.uri.toString()+"~n  SCHEME:"+workspace.uri.scheme+"~n  AUTHORITY:"+workspace.uri.authority+"~n  PATH: "+workspace.uri.path )
			If workspace.uri.scheme = uri.scheme And ..
			   workspace.uri.authority = uri.authority And ..
			   workspace.uri.path = path Then
				Return workspace
			End If
		Next
		
	End Method
	
	' Retrieve the first workspace
	Method getFirst:TWorkspace()
		For Local workspace:TWorkspace = EachIn list
			Return workspace
		Next
	End Method

	' DEBUGGING METHOD
	Method reveal:String()
		Local str:String=""
		For Local key:String = EachIn list.keys()
			Local workspace:TWorkspace = TWorkspace( list[key] )
			str :+ workspace.uri.tostring() + "~n" + workspace.reveal()
		Next
		Return str
	End Method
	
	Method shutdown()
		For Local key:String = EachIn list.keys()
			Local workspace:TWorkspace = TWorkspace( list[key] )
			If workspace ; workspace.shutdown()
		Next
		' Clean up the TMAP
		list.clear()
	End Method
	
End Type

Type TWorkspace

	Field uri:TURI

	Field documents:TMap
	Field name:String
	'Field uri:String

	' Threaded Validator
	Field DocThread:TThread
	Field QuitDocThread:Int = True
	Field semaphore:TSemaphore = CreateSemaphore( 0 )

	Method New( name:String, uri:TURI )
		Self.name = name
		Self.uri = uri
		documents = New TMap()
		
		' Create a document manager thread
		DocThread = CreateThread( DocManagerThread, Self )	' Document Manager
	End Method

	' Retrieve all documents
	Method all:TMap()
		Return documents
	End Method

	' Add a document
	Method add( uri:TURI, document:TTextDocument )
		logfile.debug( "Adding document!" )
		If Not uri logfile.debug( "uri IS NULL" )
		logfile.debug( "Adding document to "+ uri.tostring() )
		documents[ uri.toString() ] = document
		
		' Request document validation
		document.validated = False
		PostSemaphore( semaphore )
	End Method
	
	' Apply a change to a document
	Method change( doc_uri:String, changes:JSON[], version:ULong=0 )
		Local document:TFullTextDocument = TFullTextDocument( documents.valueForKey( doc_uri ) )
		If document
			document.change( changes, version )
			document.validated = False
			PostSemaphore( semaphore )
		End If
	End Method
		
	' Remove a document
	Method remove( uri:TURI )
		documents.remove( uri.toString() )
	End Method
	
	' Return or Create a given document
	Method get:TTextDocument( doc_uri:String )
		Local document:TTextDocument = TTextDocument( documents.valueForKey( doc_uri ) )
		If document ; Return document
		'Return CreateDocument( doc_uri )
	End Method
	
	Method Create:TTextDocument( uri:TURI, content:String = "", version:ULong = 0 )
		Return New TTextDocument( uri, content, version )
	End Method

	' Invalidate a document (forcing a re-validation)
	Method invalidate( document:TFullTextDocument )
		If document
			document.validated = False
			PostSemaphore( semaphore )
		End If
	End Method

	' Invalidate a document by URI
	Method invalidate( doc_uri:TURI )
		Local document:TFullTextDocument = TFullTextDocument( documents.valueForKey( doc_uri ) )
		If document
			document.validated = False
			PostSemaphore( semaphore )
		End If
	End Method

	' Validation of all documents
	Method validate()
		For Local key:String = EachIn documents.keys()
			Local document:TTextDocument = TTextDocument( documents[key] )
			If document ; document.validate()
		Next
	End Method

	' DEBUGGING METHOD
	Method reveal:String()
		Local str:String=""
		For Local key:String = EachIn documents.keys()
			Local document:TTextDocument = TTextDocument( documents[key] )
			str :+ "  "+document.uri.filename() + ", version="+document.version+"~n"
		Next
		Return str
	End Method

	' SHUTDOWN IN PROGRESS
	Method shutdown()
		' Close the document thread
		AtomicSwap( QuitDocThread, False )  ' Inform thread it must exit
		PostSemaphore( semaphore )  		' Wake the thread from it's slumber
        DetachThread( DocThread )
        logfile.debug( "Workspace '"+name+"' thread closed" )
	
		' Save cache, ast or anything should be done here!
	End Method
	
	    ' Thread to manage documents
    Function DocManagerThread:Object( data:Object )
        Local workspace:TWorkspace = TWorkspace( data )
        Local quit:Int = False          ' Always got to know when to quit!
		Repeat
			Try
                logfile.debug( "Workspace "+workspace.uri.tostring()+": Resting..")
				WaitSemaphore( workspace.semaphore )
                logfile.debug( "Workspace "+workspace.uri.tostring()+": Awoken.." )
				
				' VALIDATE DOCUMENTS
				workspace.validate()
				
            Catch Exception:String 
                'DebugLog( Exception )
                logfile.critical( Exception )
            End Try
		Until CompareAndSwap( workspace.QuitDocThread, quit, True )
	End Function
End Type
