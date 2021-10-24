
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
	Method get:TWorkspace( uri:TURI )
		If Not uri; Return Null
		
		'Local uri:TURI = TURI.file( file_uri )
		
		
		' Extract filepath from uri path (Drop the filename)
		'logfile.debug( "FOLDER IS:" + ExtractDir( uri.path ) )
		Local path:String = uri.folder()
		logfile.debug( "Finding URI: "+ uri.toString()+"~n  SCHEME:"+uri.scheme+"~n  AUTHORITY:"+uri.authority+"~n  PATH: "+path )
		
		' Match workspaces
		For Local key:String = EachIn list.keys()
			Local workspace:TWorkspace = TWorkspace( list[key] )
			logfile.debug( "Comparing: "+ workspace.uri.toString()+"~n  SCHEME:"+workspace.uri.scheme+"~n  AUTHORITY:"+workspace.uri.authority+"~n  PATH: "+workspace.uri.path )
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
	
End Type

Type TWorkspace

	Field uri:TURI

	Field documents:TMap
	Field name:String
	'Field uri:String

	Method New( name:String, uri:TURI )
		Self.name = name
		Self.uri = uri
		documents = New TMap()
	End Method

	Method all:TMap()
		Return documents
	End Method

	' Add a document
	Method add( uri:TURI, document:TTextDocument )
		logfile.debug( "Adding document!" )
		If Not uri logfile.debug( "uri IS NULL" )
		logfile.debug( "Adding document to "+ uri.tostring() )
		documents[ uri.toString() ] = document
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
		
	Method update( doc_uri:String, change:String, version:ULong=0 )
		Local document:TFullTextDocument = TFullTextDocument( documents.valueForKey( doc_uri ) )
		If Not document ; Return
		document.applychange( change )
		document.version = version
	End Method
	
	Function finduri( uri:String )
    End Function

	' DEBUGGING METHOD
	Method reveal:String()
		Local str:String=""
		For Local key:String = EachIn documents.keys()
			Local document:TTextDocument = TTextDocument( documents[key] )
			str :+ "  "+document.uri.filename() + ", version="+document.version+"~n"
		Next
		Return str
	End Method
		
End Type
