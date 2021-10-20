
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
	Field name:String		' Fallback from metadata "class"
	'Field token:TToken
	Field tokenid:Int		' This is the token id that created the node
	Field value:String		' Used in leaf nodes
	Field line:Int, pos:Int	' Not normally held in an AST, but needed for language server
	'Field definition:String	' Block comment (before) used to describe meaning
	'Field descr:String		' Optional Trailing "line" comment
	Field link:TLink		' Used in Compound nodes
	
	'Field comment:TToken	' Trailing comment or Null
	'Field valid:Int = False	' Is node valid
	Field status:Int = 0		'	0=Unknown (GREY), 1=OK, 1=Warning, 2=Error
	Field errors:TDiagnostic[]	' Invalidation messages
	
	Method New( name:String )
		Self.name  = name
	End Method

'	Method New( name:String, id:Int )
'		Self.name    = name
'		Self.tokenid = id
'	End Method

	Method New( token:TToken )
		consume( token )
	End Method

	Method New( name:String, token:TToken )
		Self.name  = name
		consume( token )
		'Self.descr = descr
	End Method

	Method class:String()
		Local T:TTypeId = TTypeId.ForObject( Self )
		Return T.metadata("class")
	End Method
	
	Method consume( token:TToken )
		Self.tokenid = token.id
		Self.value   = token.value
		Self.line    = token.line
		Self.pos     = token.pos
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
		Local block:String = ["!","."][errors.length>0]+" "+indent+getname()
		block :+ " " + Trim(showLeafText()) + "~n"
		If errors
			For Local err:TDiagnostic = EachIn errors
				block :+ " >"+indent+"  ("+err.reveal()+")~n"
			Next
		End If
		Return block
	End Method

	' Get string location
	Method loc:String( Prefix:String = " " )
		Return prefix+"["+line+","+pos+"]"
	End Method
	
	' Debugging text (Name of node taken from metadata or name)
	Method getname:String()
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local class:String = this.metadata( "class" )
		If class Return class
		Return name
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
	
	Method inorder:Object( eval:Object( node:TASTNode, data:Object ), data:Object )
		'Print getname()
		Return eval( Self, data )
	End Method
	
End Type

Type TASTError Extends TASTNode

	Method New( name:String )
		Self.name  = name
		'Self.valid = False	' INVALID BY DEFAULT
	End Method

	Method New( token:TToken )
		consume( token )
		'Self.valid = False	' INVALID BY DEFAULT
	End Method

	Method New( name:String, token:TToken )
		Self.name  = name
		consume( token )
		'Self.descr = descr
		'Self.valid = False	' INVALID BY DEFAULT
	End Method
		
	' Used for debugging tree structure
	Method reveal:String( indent:String = "" )
		Local block:String = ["!","."][errors.length>0]+" "+indent+name
		If value<>"" block :+ " "+Replace(value,"~n","\n")
		block :+ "~n"
		If errors
			For Local err:TDiagnostic = EachIn errors
				block :+ " >"+indent+"  ("+err.reveal()+")~n"
			Next
		End If
		Return block
	End Method

End Type
