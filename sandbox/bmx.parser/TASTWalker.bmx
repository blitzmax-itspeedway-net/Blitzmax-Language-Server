
'	LANGUAGE SERVER / TEXT DOCUMENT
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TASTWalker Extends TVisitor

	Field ast:TASTNode

	Method New( ast:TASTNode )
		Self.ast = ast
	End Method
	
	' Search for nodes of a specific type
	Method search:TList( criteria:Int[] )
'DebugStop
		Local list:TList = New TList()

		'list = TASTNode[]( 
		ast.inorder( Walker, list, criteria )
		
		' Convert list into a string so we can display it
		'Local result:String
		'For Local node:TASTNode = EachIn list
	'	'	result :+ node.reveal()+"~n"
		'Next
		'logfile.debug( "WALKER.SEARCH~n"+result )
		
		Return list
	End Method
	
	Function Walker:Object( node:TASTNode, data:Object, options:Int[])
'DebugStop
		' Check if node found
		If Not in( node.tokenid, options ); Return data
'DebugStop
		' Add node to results
		Local list:TList = TList(data)
		list.addlast( node )
		Return list

	End Function

End Type