
'	ABSTRACT SYNTAX TREE / NODE
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	CHANGE LOG
'	V1.0	07 AUG 21	Initial version
'	V1.1	17 AUG 21	Added consume()

Const AST_NODE_UNKNOWN:Int	= 0		' GREY
Const AST_NODE_OK:Int		= 1		' GREEN
Const AST_NODE_WARNING:Int	= 2		' YELLOW
Const AST_NODE_ERROR:Int	= 3		' RED

' An Abstract Syntax Tree Leaf Node
Type TASTNode
	Field parent:TASTNode
	'Field class:Int
	'Field name:String		' Fallback from metadata "class"
	Field classname:String		' Fallback from metadata "class"
	'Field token:TToken
	Field tokenid:Int		' This is the token id that created the node
	Field value:String		' Used in leaf nodes
	'Field definition:String	' Block comment (before) used to describe meaning
	'Field descr:String		' Optional Trailing "line" comment

	' Not normally held in an AST, but needed for language server
	'Field line:Int, pos:Int		' DEPRECIATED 6/11/21
	Field start_line:UInt
	Field start_char:UInt
	Field end_line:UInt
	Field end_char:UInt
	
	' Used by compound nodes
	Field link:TLink
	
	'Field comment:TToken	' Trailing comment or Null
	'Field valid:Int = False	' Is node valid
	'Field status:Int = 0		'	0=Unknown (GREY), 1=OK, 1=Warning, 2=Error
	Field errors:TASTErrorMessage[]	' Invalidation messages
	
	'Method New( name:String )
	'	Self.name  = name
	'End Method

'	Method New( name:String, id:Int )
'		Self.name    = name
'		Self.tokenid = id
'	End Method

	Method New( token:TToken )
		consume( token )
	End Method

	'Method New( name:String, token:TToken )
	'	Self.name  = name
	'	consume( token )
	'	'Self.descr = descr
	'End Method

	Method class:String()
		Local T:TTypeId = TTypeId.ForObject( Self )
		Return T.metadata("class")
	End Method
	
	Method consume( token:TToken )
		Self.tokenid    = token.id
		Self.value      = token.value
		Self.start_line = token.line
		Self.start_char = token.pos
		Self.end_line   = token.line
		Self.end_char   = token.pos + token.value.length
		If token.value ; Self.end_char :+ token.value.length
	End Method
	
	'Method walk:Object( evaluator( node:TASTNode, result:Object ), result:Object ) 
	'	Local node:TASTNode = walkfirst()
	'	evaluator( node, result )
	'End Method
	
	' Walk the tree to find left-most leaf
	Method walkfirst:TASTNode() 
		Return Self
	End Method
	
	' A Leaf has not decendents go automatically passes to parent.
	'Method walknext:TASTNode()
	'	Return parent
	'End Method
	
	' Obtain the preceeding node
	'Method preceeding:TASTNode()
	'	If parent Return parent.previous( Self )
	'	Return Null
	'End Method
	
	' Obtain the child prior to given node
	'Method previous:TASTNode( given:TASTNode )
	'	Return Null
	'End Method
	
	' Used for debugging tree structure
	Method reveal:String( indent:String = "" )
		Local block:String = ["!","."][errors.length>0]
		block :+ " " + pos()[..9] + " " + indent.length
		block :+ " " + indent+getname()
		block :+ " " + Trim(showLeafText()) + "~n"
		If errors
			For Local err:TASTErrorMessage = EachIn errors
				block :+ " >"+indent+"  ("+err.reveal()+")~n"
			Next
		End If
		Return block
	End Method

	' Get string location
	Method loc:String()
		Return "["+start_line+","+start_char+"]-["+end_line+","+end_char+"]"
	End Method

	' Get string position
	Method pos:String()
		Return "["+start_line+","+start_char+"]"
	End Method
	
	' Debugging text (Name of node taken from metadata)
	Method getname:String()
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local class:String = this.metadata( "class" )
		'If class Return class
		Return class	'name
	End Method
	
	' Debugging text (Leaf value)
	Method showLeafText:String()
		Return Replace(value,"~n","\n")
	End Method
	
	' Confirm validity of a node
	Method isValid:Int()
		Return (errors=Null)
	End Method
	
	' Validate the node
	' By default it is invalid forcing a validate function to be added to node
	Method validate() ; End Method
	
	' TREE TRAVERSAL
	' - INORDER   = LEFT, ROOT, RIGHT
	' - PREORDER  = ROOT, LEFT, RIGHT
	' - POSTORDER = LEFT, RIGHT, ROOT
	
	Method inorder:Object( eval:Object( node:TASTNode, data:Object, options:Int ), data:Object, options:Int=0 )
		If data ; Return eval( Self, data, options )
		Return data
	End Method

	Method inorder:Object( eval:Object( node:TASTNode, data:Object, options:Int[] ), data:Object, options:Int[]=[] )
		If data ; Return eval( Self, data, options )
		Return data
	End Method
	
End Type

Type TASTError Extends TASTNode {class="error"}

	'Method New( name:String )
	'	Self.name  = name
	'	'Self.valid = False	' INVALID BY DEFAULT
	'End Method

	Method New( token:TToken )
		consume( token )
		'Self.valid = False	' INVALID BY DEFAULT
	End Method

	'Method New( name:String, token:TToken )
	'	Self.name  = name
	'	consume( token )
	'	'Self.descr = descr
	'	'Self.valid = False	' INVALID BY DEFAULT
	'End Method
		
	' Used for debugging tree structure
	Method reveal:String( indent:String = "" )
		Local block:String = ["!","."][errors.length>0]
		block :+ " " + pos()[..9] + " " + indent.length
		block :+ " " + indent+getName()
		If value<>"" block :+ " "+Replace(value,"~n","\n")
		block :+ "~n"
		If errors
			For Local err:TASTErrorMessage = EachIn errors
				block :+ " >"+indent+"  ("+err.reveal()+")~n"
			Next
		End If
		Return block
	End Method

End Type
