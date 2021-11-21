
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

' Add to task queue as UNIQUE/LOW priority
' pushTaskQueue( task, True )

Type TWorkspaceScanTask Extends TTask
	
	Const PROGRESS_FREQUENCY:Int = 1000
		
	Field folder:String
	
	' Threads
	Field thread:TThread
	Field quit:Int

	Method New( folder:String )
		name = "WorkspaceScan{"+folder+"}"
		priority = 5	' Low priority task
		Self.folder = folder
	End Method
	
	Method execute()
	
		' Create a progress bar
		' Create a thread to run within
		thread = CreateThread( Threaded_Scanner, Self )
		' Begin
		
	End Method
	
	Method progress( percent:Int )
	End Method

	Function Threaded_Scanner:Object( data:Object )
		Local this:TWorkspaceScanTask = TWorkspaceScanTask( data )
		If Not this ; Return
		
		' First we get all BMX files in the workspace
		
		
	End Function

	' Folder scanner
	Function dir_scanner:String[]( folder:String, list:String[] Var )
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
	End Function
End Type