
'	ABSTRACT SYNTAX TREE / UNARY NODE
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

' A Grouped AST Node (Essentially a node that appears within brackets)
'	"(" expression ")"

Type TASTGroup Extends TASTNode
	Field node:TASTNode
	
	Method New( node:TASTNode )
		Self.node = node
	End Method

	' Used for debugging tree structure
	Method reveal:String( indent:String = "" )
		Local block:String = ["!","."][errors.length>0]
		block :+ " " + pos()[..9] + " " + indent.length
		block :+ " " + indent+getname()
		block :+ " ( " + Trim(showLeafText()) + " ) ~n"
		If node ; block :+ node.reveal( indent+" " )
		If errors
			For Local err:TASTErrorMessage = EachIn errors
				block :+ " >"+indent+"  ("+err.reveal()+")~n"
			Next
		End If
		Return block
	End Method

	' TREE TRAVERSAL

	' Walk the tree to find left-most leaf
	Method walkfirst:TASTNode()
		If Not node Return Self
		Return node.walkFirst()
	End Method
		
	Method inorder:Object( eval:Object( node:TASTNode, data:Object, options:Int ), data:Object, options:Int=0 )
		If data And node ; data = node.inorder( eval, data, options )
		Return data
	End Method
End Type