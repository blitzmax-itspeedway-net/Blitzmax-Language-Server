
'	ABSTRACT SYNTAX TREE / UNARY NODE
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

' A Unary AST Node
Type TASTUnary Extends TASTNode
	Field operation:TToken, node:TASTNode
	
	Method New( Operation:TToken, node:TASTNode )
		Self.operation = operation
		Self.node = node
	End Method
	
	' Walk the tree to find left-most leaf
	Method walkfirst:TASTNode()
		If node Return node.walkfirst()
		Return Self
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
		If node
			block :+ node.reveal( indent+"  " )
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
	' - INORDER   = ROOT, RIGHT
	' - PREORDER  = ROOT, RIGHT
	' - POSTORDER = RIGHT, ROOT
	
	Method inorder:Object( eval:Object( node:TASTNode, data:Object, options:Int ), data:Object, options:Int=0 )
		' Unary types are validated BEFORE children
		If data ; data = eval( Self, data, options )
		If data And node ; data = node.inorder( eval, data, options )
		Return data
	End Method
	
End Type