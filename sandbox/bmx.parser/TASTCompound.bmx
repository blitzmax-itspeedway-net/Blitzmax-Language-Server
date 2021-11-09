
'	ABSTRACT SYNTAX TREE / COMPOUND NODE
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	CHANGE LOG
'	V1.0	07 AUG 21	Initial version

' A Compound AST Node with multiple children
Type TASTCompound Extends TASTNode
	Field children:TList

	Method New( name:String )
		Self.name  = name
		children = New TList()
	End Method

	Method New( token:TToken )
		consume( token )
		children = New TList()
	End Method
		
	' Walk the tree to find left-most leaf
	Method walkfirst:TASTNode()
		If children.isempty() Return Self
		Return TASTNode(children.first()).walkFirst()
	End Method
	
	' Obtain the child prior to given node
	'Method previous:TASTNode( given:TASTNode )
	'	If given And given.link Return TASTNode(given.link.prevlink.value())
	'	Return Null
	'End Method

	' Add a child
	Method add( child:TASTNode )
		child.link = children.addlast( child )
	End Method
	
	' Insert a child at top
'	Method insert( child:TASTNode )
'		child.link = children.addfirst( child )
'	End Method

	' Used for debugging tree structure
	Method reveal:String( indent:String = "" )
		Local block:String = ["!","."][errors.length>0]+" "+indent+getname()
		block :+ " " + Trim(showLeafText()) + "~n"
		'If value<>"" block :+ " "+Replace(value,"~n","\n")
		'block :+ "~n"
		If errors
			For Local err:TASTErrorMessage = EachIn errors
				block :+ " >"+indent+"  ("+err.reveal()+")~n"
			Next
		End If
		If Not children Return block
		For Local child:TASTNode = EachIn children
			block :+ child.reveal( indent+"  " )
		Next
		Return block
	End Method
	
	' Validate the node and it's children
	Method validate()
		'valid = ( error.length=0 ) ' Only valid if there is no error!
		If Not children Return
		For Local child:TASTNode = EachIn children
			child.validate()
			'valid = Min( valid, child.valid )
		Next
	End Method
	
	' TREE TRAVERSAL
	' - INORDER   = LEFT, ROOT, RIGHT
	' - PREORDER  = ROOT, LEFT, RIGHT (CHILDREN)
	' - POSTORDER = LEFT, RIGHT, ROOT

	Method inorder:Object( eval:Object( node:TASTNode, data:Object, options:Int ), data:Object, options:Int = 0 )
		If children
			For Local child:TASTNode = EachIn children
				If data ; data = child.inorder( eval, data, options )
			Next
		End If
		If data ; data = eval( Self, data, options )
		Return data
	End Method

End Type