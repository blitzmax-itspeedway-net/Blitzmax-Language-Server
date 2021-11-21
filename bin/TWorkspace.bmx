
'	WORKSPACE MANAGER
'	(c) Copyright Si Dunford, October 2021, All Rights Reserved

Const CACHE_FOLDER:String = ".bls-cache"
Const CACHE_FILE:String = "workspace.cache"

Type TWorkspaces Extends TEventHandler

	Global list:TMap = New TMap()
		
	' Add a Workspace
	Method add( uri:TURI, workspace:TWorkspace )
logfile.debug( "# Adding workspace '"+uri.tostring()+"'" )
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
'If uri
'	logfile.debug( "uri is "+uri.toString() )
'Else
'	logfile.debug( "uri is NULL" )
'EndIf
		If uri ; Return get( uri )
	End Method
	
	Method get:TWorkspace( uri:TURI )
		If Not uri; Return Null
		
		'Local uri:TURI = TURI.file( file_uri )
		
		
		' Extract filepath from uri path (Drop the filename)
		'logfile.debug( "FOLDER IS:" + ExtractDir( uri.path ) )
		Local path:String = uri.folder()
		Local candidate:TWorkspace
		'logfile.debug( "Finding URI: "+ uri.toString()+"~n  SCHEME:"+uri.scheme+"~n  AUTHORITY:"+uri.authority+"~n  PATH: "+path )
		
		' Match workspaces
		For Local key:String = EachIn list.keys()
			Local workspace:TWorkspace = TWorkspace( list[key] )
			'logfile.debug( "Comparing: "+ workspace.uri.toString()+"~n  SCHEME:"+workspace.uri.scheme+"~n  AUTHORITY:"+workspace.uri.authority+"~n  PATH: "+workspace.uri.path )
			If workspace.uri.scheme = uri.scheme And ..
			   workspace.uri.authority = uri.authority 
				If workspace.uri.path = path
					' We have a match
					Return workspace
				ElseIf path.startswith( workspace.uri.path )
					' We have a candidate
					If Not candidate Or Len( workspace.uri.path ) > Len( candidate.uri.path ) ; candidate = workspace
				End If
			End If
		Next

		'logfile.debug( "# No workspace match was found" )
		'If candidate ; logfile.debug( "# Using candidate "+candidate.uri.toString() )

		' We get here if no exact match has been found
		' In this case, we return the closest candidate (if found)
		If candidate ; Return candidate
		
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
	'	For Local key:String = EachIn list.keys()
	'		Local workspace:TWorkspace = TWorkspace( list[key] )
	'		If workspace ; workspace.shutdown()
	'	Next
	'	' Clean up the TMAP
		list.clear()
	End Method
	
End Type

Type TWorkspace

	Field uri:TURI
	Field cachefile:String = ""
	
	Field documents:TMap
	Field name:String
	'Field uri:String

	' Object lock
	Field lock:TMutex = CreateMutex()

	' Threaded Validator
	'Field DocThread:TThread
	'Field QuitDocThread:Int = True
	'Field semaphore:TSemaphore = CreateSemaphore( 0 )

	' Threaded document scanner
	'Field scanThread:TThread
	'Field scanThreadExit:Int = False


	Method New( name:String, uri:TURI )
		Self.name = name
		Self.uri = uri
		Local location:String = uri.path
		documents = New TMap()

		' Check if workspace contains a cache folder
'		logfile.debug( "# WORKSPACE IS "+uri.tostring()+", "+location )
		If location <> "/"
'			logfile.debug( "# WORKSPACE IS NOT ROOT ("+location+")" )
			Local cachefolder:String = location + "/" + CACHE_FOLDER
'			logfile.debug( "# CACHE FOLDER("+cachefolder+")" )
			Select FileType( cachefolder )
			Case 0	' DOES NOT EXIST
'				logfile.critical( "# WORKSPACE CACHE FOLDER DOES NOT EXIST" )
				If CreateDir( cachefolder ) 
'					logfile.critical( "# CREATED CACHE FOLDER" )
					cachefile = cachefolder + "/" + CACHE_FILE
				Else
					logfile.critical( "# UNABLE TO CREATE CACHE FOLDER" )
					client.logmessage( "Unable to create cache folder.", EMessageType.Error.ordinal() )
				End If
			Case FILETYPE_FILE
				logfile.critical( "# WORKSPACE CACHE FOLDER IS A FILE!" )
				client.logmessage( "Workspace cache folder is a File! Please delete it!", EMessageType.Error.ordinal() )
			Case FILETYPE_DIR
'				logfile.debug( "# WORKSPACE CACHE FOLDER EXISTS" )
			End Select
		End If

		' Create a document manager thread
		' OLD: Please use a task!
		'DocThread = CreateThread( DocManagerThread, Self )	' Document Manager
		
		' Create thread to scan workspace for documents
		If location = "/"
			logfile.debug( "## NOT RUNNING SCANNER ON ROOT" )
		Else
			logfile.debug( "## RUNNING SCANNER ON "+location )
			' scanThread = new TThread( WorkSpaceScan, self )	
		End If

		' Request Workspace configuration
		getConfiguration()
	End Method

	' Retrieve all documents
	Method all:TMap()
		Return documents
	End Method

	' Add a document
	Method add( uri:TURI, document:TTextDocument )
		'logfile.debug( "Adding document!" )
		'If Not uri logfile.debug( "uri IS NULL" )
		'logfile.debug( "Adding document to "+ uri.tostring() )
		documents[ uri.toString() ] = document
		
		' Request document validation
		document.validated = False
		'PostSemaphore( semaphore )
	End Method
	
	' Apply a change to a document
	Method change( doc_uri:String, changes:JSON[], version:Int=0 )
		Local document:TFullTextDocument = TFullTextDocument( documents.valueForKey( doc_uri ) )
		If document
			document.change( changes, version )
			document.validated = False
			'PostSemaphore( semaphore )
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
			'PostSemaphore( semaphore )
		End If
	End Method

	' Invalidate a document by URI
	Method invalidate( doc_uri:TURI )
		Local document:TFullTextDocument = TFullTextDocument( documents.valueForKey( doc_uri ) )
		If document
			document.validated = False
			'PostSemaphore( semaphore )
		End If
	End Method

	' Validation of all documents
	Method validate()
logfile.debug( "# VALIDATING DOCUMENTS" )
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
	'Method shutdown()
		' Close the document thread
		'AtomicSwap( QuitDocThread, False )  ' Inform thread it must exit
		'PostSemaphore( semaphore )  		' Wake the thread from it's slumber
        'DetachThread( DocThread )
        'logfile.debug( "Workspace '"+name+"' thread closed" )
	
		' Save cache, ast or anything should be done here!
	'End Method
	
	' Get workspace configuration
	Method getConfiguration()
		' Register for Configuration updates (If supported by client)
		If client.has( "workspace|configuration" )
			logfile.debug( "# Client supports workspace configuration" )
			
			' Create a JSON array for the configuration Parameters
			Local configParams:JSON = New JSON( JSON_ARRAY )

			' Create ConfigurationItem array
			Local configurationItem:JSON = New JSON()
			configurationItem.set( "scopeUri", uri.tostring() )
			'configurationItem.set( "section","tasks")
			configParams.addlast( configurationItem )
			
			'config = New JSON()
			'config.set( "scopeUri", "resource" )
			'config.set( "section","blitzmax")
			'configParams.addlast( config )

			' Create a response and add configParams
			Local request:JSON = EmptyResponse( "workspace/configuration" )
			request.set( "params", configParams )			
			lsp.send( request )
		End If
	End Method
	
	    ' Thread to manage documents
Rem
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
End Rem	

	' Scan a workspace folder to obtain a list of files within it
Rem	Method scan:String[]( folder:String, list:String[] Var )
		Local dir:Byte Ptr = ReadDir( folder )
		If Not dir Return Null
		Repeat
			Local filename:String = NextFile( dir )
			If filename="" Exit
			If filename="." Or filename=".." Continue
			Select FileType( folder+"/"+filename )
			Case FILETYPE_DIR
				workspace_scan2( folder + "/" + filename, list )
			Case FILETYPE_FILE
				If Lower(ExtractExt(filename))="bmx" ; list :+ [ folder+"/"+filename ]
			End Select
		Forever
		CloseDir dir
	End Method
End Rem
End Type
