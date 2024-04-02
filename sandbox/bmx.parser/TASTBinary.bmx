
'	ABSTRACT SYNTAX TREE / BINARY NODE
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	CHANGE LOG
'	V1.0	07 AUG 21	Initial version

' A binary AST Node (TRUE/FALSE, LEFT/RIGHT etc)
Type TASTBinary Extends TASTNode
	Field lnode:TASTNode, operation:TToken, rnode:TASTNode
	
	Method New( lnode:TASTNode, Operation:TToken, rnode:TASTNode )
		Self.lnode = lnode
		Self.operation = operation
		Self.rnode = rnode
	End Method
	
	' Walk the tree to find left-most leaf
	Method walkfirst:TASTNode()
		If lnode Return lnode.walkfirst()
		Return lnode
	End Method

	' Obtain the child prior to given node
	'Method previous:TASTNode( given:TASTNode )
	'	If given=rnode Return lnode
	'	Return Null
	'End Method

	' Used for debugging tree structure
	Method reveal:String( indent:String = "" )
		Local block:String = indent+getname()
		If value<>"" block :+ " "+Replace(value,"~n","\n")
		block :+ "~n"
		If lnode
			block :+ lnode.reveal( indent+"  " )
		Else
			block :+ "NULL~n"
		End If
		If rnode
			block :+ rnode.reveal( indent+"  " )
		Else
			block :+ "NULL~n"
		End If
		If errors
			For Local err:TASTErrorMessage = EachIn errors
				block :+ " >"+indent+"  ("+err.reveal()+")~n"
			Next
		End If
		Return block
	End Method

	' TREE TRAVERSAL
	' - INORDER   = LEFT, ROOT, RIGHT
	' - PREORDER  = ROOT, LEFT, RIGHT
	' - POSTORDER = LEFT, RIGHT, ROOT
	
	Method inorder:Object( eval:Object( node:TASTNode, data:Object, options:Int ), data:Object, options:Int=0 )
		' Binary types are validated BETWEEN children
		If data And lnode ; data = lnode.inorder( eval, data, options )
		If data ; data = eval( Self, data, options )
		If data And rnode ; data = rnode.inorder( eval, data, options )
		Return data
	End Method

	Method inorder:Object( eval:Object( node:TASTNode, data:Object, options:Int[] ), data:Object, options:Int[]=[] )
		' Binary types are validated BETWEEN children
		If data And lnode ; data = lnode.inorder( eval, data, options )
		If data ; data = eval( Self, data, options )
		If data And rnode ; data = rnode.inorder( eval, data, options )
		Return data
	End Method

End Type
