
'	WORKSPACE MANAGER
'	(c) Copyright Si Dunford, October 2021, All Rights Reserved

Type TWorkspaces

	Global list:TMap = New TMap()
	
'TODO: Need to generate a UUID here:
	field ChangeNotificationID:String = "00-123456-123456-abcdef"
	
	Method New()
		' Incremental document sync
		lsp.capabilities.set( "textDocumentSync", TextDocumentSyncKind.INCREMENTAL.ordinal() )
		' Register for code completion events
		lsp.capabilities.set( "definitionProvider", "true" )
		' Register for definition provide events
		lsp.capabilities.set( "completionProvider|resolveProvider", "true" )
		
'TODO: Only enable is client supports them
		' Register for Workspace support
' NEED TO SEND THIS - IT IS NOT A MESSAGE:
		'lsp.capabilities.set( "workspace|workspaceFolders|supported", "true" )
		'lsp.capabilities.set( "workspace|workspaceFolders|changeNotifications", ChangeNotificationID )
		
		'lsp.capabilities.set( "workspace|workspaceFolders|supported", "true" )
		
				

	End Method
	
	' workspace/did_change_workspace_folders
	Function didChangeWorkspaceFolders( event:String )	':JSON )
		
		'added = event.find( "added" )
		'removed = event.find( "removed" )
		
		Rem
		for local item:string = eachin removed
			list.remove( item )
		next
		
		for local item:string = eachin added
			local file_uri:string = item.find("uri")
			list.insert( 
			
			' workspaceconfig = config.config( file_uri, default_options )
			list.insert( file_uri, new TWorkspace( file_uri )
		next
		
		
		End Rem
		
	End Function
	
	Function didChangeConfiguration( event:String )
	End Function
	
	Function didChangeWatchedFiles( event:String )
	End Function
	

	' Find a workspace for a given file
	Method get:TWorkspace( file_uri:String )
		If Not file_uri ; Return Null
		
		Local doc:URI = URI.file( file_uri )
		
		' Match workspaces
		For Local workspace:TWorkspace = EachIn list
			If workspace.workspace.scheme = doc.scheme And ..
			   workspace.workspace.authority = doc.authority And ..
			   workspace.workspace.path = doc.path Then
				Return workspace
			End If
		Next
		
	End Method
	

End Type

Type TWorkspace

	Field workspace:URI

	Field documents:TMap
	Field rooturi:String

	Method New( rooturi:String )
		Self.rooturi = rooturi
		documents = New TMap()
		
		
		
	End Method

	Method all:TMap()
		Return documents
	End Method
	
	' Return or Create a given document
	Method get:TTextDocument( doc_uri:String )
		Local document:TTextDocument = TTextDocument( documents.valueForKey( doc_uri ) )
		If document ; Return document
		'Return CreateDocument( doc_uri )
	End Method
	
	Method Create:TTextDocument( doc_uri:String, content:String = "", version:ULong = 0 )
		Return New TTextDocument( doc_uri, content, version )
	End Method
	
	Method remove( doc_uri:String )
		documents.remove( doc_uri )
	End Method
	
	Method update( doc_uri:String, change:String, version:ULong=0 )
		Local document:TFullTextDocument = TFullTextDocument( documents.valueForKey( doc_uri ) )
		If Not document ; Return
		document.applychange( change )
		document.version = version
	End Method
	
	Function finduri( uri:String )
    End Function
	
End Type
