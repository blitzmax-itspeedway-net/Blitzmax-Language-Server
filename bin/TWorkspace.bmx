
'	WORKSPACE MANAGER
'	(c) Copyright Si Dunford, October 2021, All Rights Reserved

Type TWorkspace

	Field uri:TURI
	Field cachefile:String = ""		' Name of the cache file
	Field cache:TWorkspaceCache
	
	Field documents:TMap
	Field name:String
	'Field uri:String

	' Object lock
	Field lock:TMutex = CreateMutex()

	'Field symbolTable:TSymbolTable = Null
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

		' Create/Open Workspace Cache
		cache = New TWorkspaceCache( location )
				
Rem	
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
End Rem

		' Create a document manager thread
		' OLD: Please use a task!
		'DocThread = CreateThread( DocManagerThread, Self )	' Document Manager
		
		' Create thread to scan workspace for documents
		
		If location = "/"
			logfile.debug( "## NOT RUNNING SCANNER ON ROOT" )
		Else
			logfile.debug( "## RUNNING SCANNER ON "+location )
			' scanThread = new TThread( WorkSpaceScan, self )	
			Local task:TTaskWorkspaceScan = New TTaskWorkspaceScan( Self )
			task.post()
		End If

		' Request Workspace configuration
		getConfiguration()
	End Method

	' Retrieve all documents
	Method all:TMap()
		Return documents
	End Method

	' Add a document reference
'	Method addOrInsert:TTextDocument( uri:TURI )
'		If Not uri ; Return	Null
'		Local index:String = uri.toString() 	
'		Local document:TTextDocument
'		If documents.contains( index )
'			' Document already exists (Which it should)
'			document = TTextDocument( documents[ index ] )
'		Else
'			' Create the document
'			document = New TTextDocument( uri )
'			documents[ index ] = document
'		End If
'		Return document
'	End Method

	' Add a document to the workspace
	Method add( document:TTextDocument )
		If Not document ; Return
		Local index:String = document.uri.toString()
		logfile.debug( "-Adding "+index+" to workspace" )
		If documents.contains( index ) ; Return			' Just ignore...
		' Add document to list
		documents[ index ] = document
	End Method

	' Confirm if a document exists in the workspace
	Method exists:Int( document:TTextDocument )
		If Not document ; Return False
		Return documents.contains( document.uri.toString() )
	End Method
	
	' Open a file in the workspace
	Method open( uri:TURI, content:String, version:UInt )

		Try
			Local document:TTextDocument
			Local index:String = uri.tostring()

			' Add or Insert the document
			If documents.contains( index )
				document = TTextDocument( documents.valueForKey( index ) )
			Else
				' Document does not exist
				' This can happen if a document is added outside of IDE and then opened
				document = New TTextDocument( uri )
				documents[ index ] = document
				'
				' Add document to cache
				cache.addDocument( document )
			End If
		
			' Populate document
			document.isOpen = True
			document.content = content
			document.version = version

			' Create PARSE task
			Local task:TTaskDocumentParse = New TTaskDocumentParse( document, Self )
			task.post()
		
'			Local document:TFullTextDocument = New TFullTextDocument( uri, Text, version )
'			logfile.debug( "Created document" )
'	If Not document logfile.debug( "DOCUMENT IS NULL" )
'			If workspace And document
'				logfile.debug( "Got workspace" )
'				' Add document to workspace
'				workspace.add( uri, document )
'	'logfile( "Document is in workspace: "+workspace.name )
'				logfile.debug( "WORKSPACES:~n"+workspaces.reveal() )
'				
'				' Invalidate document
'				workspace.invalidate( document )
'				
'				' Create PARSE task
'				Local task:TTaskDocumentParse = New TTaskDocumentParse( document, True )
'				task.post( QUEUE_PRIORITY_DOCUMENT_PARSE )
'				
'				' Run Linter
'				'lint( document )
'			
'				' Wake up the Document Thread
'				'PostSemaphore( semaphore )
'			End If
			logfile.debug( "WORKSPACES:~n"+workspaces.reveal() )

		Catch Exception:Object
			logfile.critical( "## EXCEPTION: TWorkspace.open()~n"+Exception.toString() )
		End Try
	End Method

	' Apply a change to a document
	Method change( doc_uri:String, changes:JSON[], version:Int=0 )
		Local document:TTextDocument = TTextDocument( documents.valueForKey( doc_uri ) )
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
	Method invalidate( document:TTextDocument )
		If document
			document.validated = False
			'PostSemaphore( semaphore )
		End If
	End Method

	' Invalidate a document by URI
'	Method invalidate( doc_uri:TURI )
'		Local document:TTextDocument = TTextDocument( documents.valueForKey( doc_uri ) )
'		If document
'			document.validated = False
'			'PostSemaphore( semaphore )
'		End If
'	End Method

	' Validation of all documents
'	Method validate()
'logfile.debug( "# VALIDATING DOCUMENTS" )
'		For Local key:String = EachIn documents.keys()
'			Local document:TTextDocument = TTextDocument( documents[key] )
'			If document ; document.validate()
'		Next
'	End Method

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
			Local request:JSON = EmptyRequest( "workspace/configuration" )
			request.set( "params", configParams )			
			'Local request:JSON = EmptyResponse( "workspace/configuration" )
			'request.set( "params", configParams )			
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
