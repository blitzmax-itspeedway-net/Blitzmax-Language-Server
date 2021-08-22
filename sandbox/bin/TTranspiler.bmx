
'	TRANSPILER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TTranspiler Extends TVisitor

	Field ast:TASTNode
	
	Method New( ast:TASTNode )
		Self.ast = ast
	End Method
	
	' Create source code from the AST
	Method run:String()
'DebugStop
		Local text:String = visit( ast )
		Return text
	End Method
	
	Method reveal:String()
	End Method
	
	Method header:String() Abstract
	
	' STATIC METHODS
		
	Method visitChildren:String( node:TASTCompound, indent:String="" )
		Local text:String
'DebugStop
		For Local child:TASTNode = EachIn node.children
			text :+ visit( child, indent+"\t" )
		Next
		Return text
	End Method

	' ABSTRACT METHODS

	Method visit_program:String( node:TASTCompound, indent:String="" )
		Local text:String = header()
		text :+ visitChildren( node )
		Return text
	End Method

	Method visit_EOL:String( node:TASTNode )
		Return "~n"
	End Method
	
End Type
