
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Performs a file scan of a workspace folder looking for added, removed or changed files.

Type TTaskWorkspaceScan Extends TTask
		
	Field workspace:TWorkspace

	Method New( workspace:TWorkspace, priority:Int = QUEUE_PRIORITY_WORKSPACE_SCAN )
		Super.New( BLOCKING )
		name = "WorkspaceScan{"+workspace.uri.path+"}"
		
		Self.priority = priority
		Self.workspace = workspace
		
		' Request a work-done token
		If client.has( "workspace|symbol|workDone" )
		' local workdone:TTask = new TRequestTask( TClient.progress_register:String() )
		
		' Need to register a request so we receive a reply
		End If
		
	End Method
	
	Method launch()
		Trace.debug( "## WORKSPACE SCAN - STARTED" )
		Trace.debug( "   ("+workspace.uri.tostring()+")" )
		
		' Request known files from cache
		Local cachedfiles:TMap = workspace.cache.getDocuments()

		' Get actual files from workspace
		Local filesystem:String[]
		dir_scanner( workspace.uri.path, filesystem )
		
		' Loop through files on disk
		' If it is in the cache and it has changed - RESCAN IT
		' If it is not in the cache it is a new file - SCAN IT

		' Progress Bar
		Local progress:Int = 0
		'Local total:Int = Max( filesystem.length, cachedfiles.length )
		' Cannot do this here, because token may not have been returned
		'client.progress_begin( token )
		
		For Local filename:String = EachIn filesystem
			Local uri:TURI = New TURI( filename )

			Local file:TTextDocument = New TTextDocument( uri )
			If cachedfiles.contains( filename )
				Local document:TDBDocument = TDBDocument( cachedfiles[filename] )
				If file.file_size <> document.size Or file.file_date <> document.date Or file.file_checksum <> document.checksum
					Trace.debug( "## WORKSPACE SCAN - CHANGED FILE '"+filename+"'" )
					' Add it to the workspace:
					workspace.add( file )
					' Add it to the cache:
					workspace.cache.addDocument( file )
					' Create task to rescan document
					Local task:TTaskDocumentParse = New TTaskDocumentParse( file, workspace )
					task.post()
				Else
					' File has not changed, add it to the workspace:
					workspace.add( file )				
				End If
				' Remove from cachedfiles as we've processed it.
				cachedfiles.remove( filename )
			Else
				Trace.debug( "## WORKSPACE SCAN - ADD FILE '"+filename+"'" )
				' Add it to the workspace:
				workspace.add( file )
				' Add it to the cache:
				workspace.cache.addDocument( file )
				' Create task to scan document
				Local task:TTaskDocumentParse = New TTaskDocumentParse( file, workspace )
				task.post()
			End If
			
			' Update progress bar
			progress :+ 1
			'client.progress_update( token, progress, total )
		Next

		' Files remaining in cachedfiles list exist in database, but not on disk
		For Local filename:String = EachIn cachedfiles.keys()
			Trace.debug( "## WORKSPACE SCAN - REMOVE DELETED FILE '"+filename+"'" )
			workspace.cache.DeleteDocument( filename )
			' Update progress bar
			progress :+ 1
			'client.progress_update( token, progress, total )
		Next
		'client.progress_close( token )

		Trace.debug( "## WORKSPACE SCAN - FINISHED" )
		Trace.debug( workspaces.reveal() )
	End Method
	
	Method progress( percent:Int )
	End Method

	' This method recieves responses from client if you send any requests.
	Method response( message:TMessage )
	End Method

	' Folder scanner
	Function dir_scanner( folder:String, list:String[] Var )
		Local dir:Byte Ptr = ReadDir( folder )
		If Not dir Return
		Repeat
			Local filename:String = NextFile( dir )
			If filename="" Exit
			If filename="." Or filename=".." Continue
			Select FileType( folder+"/"+filename )
			Case FILETYPE_DIR
				dir_scanner( folder + "/" + filename, list )
			Case FILETYPE_FILE
				If Lower(ExtractExt(filename))="bmx" ; list :+ [ folder+"/"+filename ]
			End Select
		Forever
		CloseDir dir
	End Function
	
End Type