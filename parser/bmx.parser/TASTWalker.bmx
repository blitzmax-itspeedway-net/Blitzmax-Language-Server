
'	LANGUAGE SERVER / TEXT DOCUMENT
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TASTWalker Extends TVisitor

	Field ast:TASTNode

	Method New( ast:TASTNode )
		Self.ast = ast
	End Method
	
	' Search for nodes of a specific type
	Method searchByIDs:TList( criteria:Int[] )
'DebugStop
		Local list:TList = New TList()

		'list = TASTNode[]( 
		ast.inorder( WalkByIDs, list, criteria )
		
		' Convert list into a string so we can display it
		'Local result:String
		'For Local node:TASTNode = EachIn list
	'	'	result :+ node.reveal()+"~n"
		'Next
		'logfile.debug( "WALKER.SEARCH~n"+result )
		
		Return list
	End Method
	
	' Search for nodes of a specific type
	Method searchByID:TList( criteria:Int )
		Return searchByIDs( [criteria] )
	End Method
		
	Function WalkByIDs:Object( node:TASTNode, data:Object, options:Int[])
'DebugStop

' 4 APR 2024 - Commented out due to compile error, but need to fix
		Trace.Error( "!! ERROR, TASTWalker.bmx, line 40 - Bad Commented code, Please review. " )
'		If Not in( node.tokenid, options ); Return data
		' Check if node found
'DebugStop
		' Add node to results
		Local list:TList = TList(data)
		list.addlast( node )
		Return list

	End Function

End Type