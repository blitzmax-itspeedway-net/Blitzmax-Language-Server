
'	ABSTRACT SYNTAX TREE (AST)
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Rem
Type TAbSynTree
	Field name:String		' IMPORTANT - THIS IS USED TO CALL THE METHOD
	Field parent:TAbSynTree		' Root node when NULL
	'Field children:TList	' Leaf node when NULL
	Field token:TToken
	
	Field root:TASTNode
	
	Method New( name:String, token:TToken )
		Self.name = name
		Self.token = token
	End Method
	
	Method addChild:TAbSynTree( child:TAbSynTree )
'DebugStop
'		If Not children children = New TList()
'		children.addLast( child )
		Return child
	End Method

	Method addChild:TAbSynTree( name:String, token:TToken )
'DebugStop
		Return addchild( New TAbSynTree( name, token ) )
	End Method

	'Method walk()
	'	' We start from the root node and find the left-most node
	'	Local start:TASTNode = root.walkleft()
	'	
	'	
	'EndMethod
	
End Type
End Rem

' An Abstract Syntax Tree Leaf Node
Type TASTNode
	Field parent:TASTNode
	'Field class:Int
	Field name:String
	Field token:TToken
	Field descr:String		' Optional Trailing comment
	Field link:TLink		' Used in Compound nodes
	
	Method New( name:String )
		Self.name  = name
	End Method

	Method New( token:TToken )
		Self.token = token
	End Method
	
	'Method New( name:TASTNode

	Method New( name:String, token:TToken, desc:String = "" )
		Self.name  = name
		Self.token = token
		Self.descr = descr
	End Method
	
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
	
End Type

' A binary AST Node (TRUE/FALSE, LEFT/RIGHT etc)
Type TASTBinary Extends TASTNode
	Field lnode:TASTNode, rnode:TASTNode
	
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
		
End Type

' A Compound AST Node with multiple children
Type TASTCompound Extends TASTNode
	Field children:TList = New TList()
	
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

End Type


' A Visitor is a process that does something with the data
' A Compiler or Interpreter are the usual candidates, but
' you can use them to convert or process data in a natural way

' The Visitor uses reflection to process the Abstract Syntax Tree
Type TVisitor

	Method visit:String( node:TASTNode )
'DebugStop
		If Not node ThrowException( "Cannot visit null node" ) 
		'If node.name = "" invalid()	' Leave this to use "visit_" method
		
		' Use Reflection to call the visitor method (or an error)
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local methd:TMethod = this.FindMethod( "visit_"+node.name )
		If Not methd exception( node )
		Local text:String = String( methd.invoke( Self, [node] ))
		Return text
	End Method
	
	' This is called when node doesn't have a name...
	Method visit_:String( node:TASTNode )
		ThrowException( "Node "+node.token.class+" has no name!" )
	End Method
	
	Method exception( node:TASTNode )
		ThrowException( "Method visit_"+node.name+"() does not exist" )
	End Method
	
End Type





