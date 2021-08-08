
'	ABSTRACT SYNTAX TREE (AST)
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type AST
	Field name:String		' IMPORTANT - THIS IS USED TO CALL THE METHOD
	Field parent:AST		' Root node when NULL
	Field children:TList	' Leaf node when NULL
	Field token:TToken
	
	Method New( name:String, token:TToken )
		Self.name = name
		Self.token = token
	End Method
	
	Method addChild( child:AST )
'DebugStop
		If Not children children = New TList()
		children.addLast( child )
	End Method

	Method addChild( name:String, token:TToken )
'DebugStop
		addchild( New AST( name, token ) )
	End Method

End Type

' A Visitor is a process that does something with the data
' A Compiler or Interpreter are the usual candidates, but
' you can use them to convert or process data in a natural way

' The Visitor uses reflection to process the Abstract Syntax Tree
Type TVisitor

	Method visit( node:AST )
		DebugStop
		If Not node ThrowException( "Cannot visit null node" ) 
		'If node.name = "" invalid()	' Leave this to use "visit_" method
		
		' Use Reflection to call the visitor method (or an error)
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local methd:TMethod = this.FindMethod( "visit_"+node.name )
		If Not methd exception( node )
		methd.invoke( Self, [node] )
	End Method
	
	' This is called when node doesn't have a name...
	Method visit_( node:AST )
		ThrowException( "Node "+node.token.class+" has no name!" )
	End Method
	
	Method exception( node:AST )
		ThrowException( "Method visit_"+node.name+"() does not exist" )
	End Method
	
End Type





