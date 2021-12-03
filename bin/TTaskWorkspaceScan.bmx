
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

' Add to task queue as UNIQUE/LOW priority
' pushTaskQueue( task, True )

Type TTaskWorkspaceScan Extends TTask
	
	Const PROGRESS_FREQUENCY:Int = 1000
		
	Field workspace:TWorkspace
	
	' Threads
	Field thread:TThread
	Field quit:Int

	Method New( workspace:TWorkspace, priority:Int = QUEUE_PRIORITY_WORKSPACE_SCAN )
		name = "WorkspaceScan{"+workspace.uri.path+"}"
		Self.priority = priority
		'Self.folder = folder
		Self.workspace = workspace
	End Method
	
	Method execute()
		logfile.debug( "## WORKSPACE SCAN - STARTED" )
		logfile.debug( "   ("+workspace.uri.tostring()+")" )
		
		' Request known files from cache
		Local cachedfiles:TMap = workspace.cache.getDocuments()

		' Get actual files from workspace
		Local filesystem:String[]
		dir_scanner( workspace.uri.path, filesystem )
		
		' Loop through files on disk
		' If it is in the cache and it has changed - RESCAN IT
		' If it is not in the cache it is a new file - SCAN IT

		For Local filename:String = EachIn filesystem
			Local uri:TURI = New TURI( filename )

			Local file:TTextDocument = New TTextDocument( uri )
			If cachedfiles.contains( filename )
				Local document:TDBDocument = TDBDocument( cachedfiles[filename] )
				If file.file_size <> document.size Or file.file_date <> document.date Or file.file_checksum <> document.checksum
					logfile.debug( "## WORKSPACE SCAN - CHANGED FILE '"+filename+"'" )
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
				logfile.debug( "## WORKSPACE SCAN - ADD FILE '"+filename+"'" )
				' Add it to the workspace:
				workspace.add( file )
				' Add it to the cache:
				workspace.cache.addDocument( file )
				' Create task to scan document
				Local task:TTaskDocumentParse = New TTaskDocumentParse( file, workspace )
				task.post()
			End If
		Next

		' Files remaining in cachedfiles list exist in database, but not on disk
		For Local filename:String = EachIn cachedfiles.keys()
			logfile.debug( "## WORKSPACE SCAN - REMOVE DELETED FILE '"+filename+"'" )
			workspace.cache.DeleteDocument( filename )
		Next

		logfile.debug( "## WORKSPACE SCAN - FINISHED" )
		logfile.debug( "WORKSPACE:~n"+workspace.reveal() )
	End Method
	
	Method progress( percent:Int )
	End Method

	'Function Threaded_Scanner:Object( data:Object )
	'	Local this:TWorkspaceScanTask = TWorkspaceScanTask( data )
	'	If Not this ; Return
		
		' First we get all BMX files in the workspace
		
		
	'End Function

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