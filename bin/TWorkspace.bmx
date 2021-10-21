
'	WORKSPACE MANAGER
'	(c) Copyright Si Dunford, October 2021, All Rights Reserved

Type TWorkspaces Extends TEventHandler

	Global list:TMap = New TMap()
	
	' Add a Workspace
	Method add( uri:String, workspace:TWorkspace )
		list[ uri ] = workspace
	End Method
	
	' Remove a Workspace
	Method remove( uri:String )
		list.remove( uri )
	End Method

	' Find a workspace
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
	
	' Retrieve the first workspace
	Method getFirst:TWorkspace()
		For Local workspace:TWorkspace = EachIn list
			Return workspace
		Next
	End Method

End Type

Type TWorkspace

	Field workspace:URI

	Field documents:TMap
	Field uri:String

	Method New( uri:String )
		Self.uri = uri
		documents = New TMap()
	End Method

	Method all:TMap()
		Return documents
	End Method

	' Add a document
	Method document_add( doc_uri:String, document:TTextDocument )
		documents[ doc_uri ] = document
	End Method
	
	' Remove a document
	Method document_remove( doc_uri:String )
		documents.remove( doc_uri )
	End Method
	
	' Return or Create a given document
	Method document_get:TTextDocument( doc_uri:String )
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
