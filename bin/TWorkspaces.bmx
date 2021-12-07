
'	WORKSPACE MANAGER
'	(c) Copyright Si Dunford, October 2021, All Rights Reserved

Const CACHE_FOLDER:String = ".bls-cache"
Const CACHE_FILE:String = "workspace.cache"

Type TWorkspaces Extends TEventHandler

	Field list:TMap = New TMap()
		
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