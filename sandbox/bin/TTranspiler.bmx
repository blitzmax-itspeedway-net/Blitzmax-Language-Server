
'	TRANSPILER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TTranspiler Extends TVisitor

	Field ast:TASTNode
	
	Method New( ast:TASTNode )
		Self.ast = ast
	End Method
	
	' Create source code from the AST
	Method run:String()
		Local text:String = visit( ast )
		Return text
	End Method
	
	Method reveal:String()
	End Method
	
	Method header:String() Abstract
	
	' ABSTRACT METHODS

	Method visit_program:String( node:TASTCompound )
		Local text:String = header()
		For Local child:TASTNode = EachIn node.children
			text :+ visit( child )
		Next
		Return text
	End Method
	
End Type
