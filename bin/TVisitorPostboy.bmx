
'	LANGUAGE SERVER / TEXT DOCUMENT
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TVisitorPostboy Extends TVisitor

	Method New()
	End Method
	
	' Search for nodes of a specific type
	Method search:TASTNode[]( criteria:Int[] )

		Local list:TASTNode[] = Null

		list = TASTNode[]( ast.inorder( Postboy, list, criteria ) )
		
		' Convert list into a string so we can display it
		Local result:String
		For Local node:TASTNode = EachIn list
			result :+ node.reveal()+"~n"
		Next
		logfile.debug( "POSTBOY.SEARCH~n" )
		
	End Method
	
	Function PostBoy:Object( node:TASTNode, data:Object, options:Int )
'DebugStop
		If node.errors.length = 0 Return data
'DebugStop
		' Convert data into a list and append to it
		Local list:TDiagnostic[] = TDiagnostic[]( data )
		'Local result:String
		'For Local i:Int = 0 Until node.errors.length
			'list :+ [ node.errors[i] ]
			'result :+ errors[n] + "["+node.line+","+node.pos+"] "+node.error+" ("+node.getname()+")~n"
			'result :+ errors[n] + "["+node.line+","+node.pos+"] ("+node.getname()+")~n"
		'	list.addlast( error )
		'Next 
		Return list + node.errors
	End Function

End Type