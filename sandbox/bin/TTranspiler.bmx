
'	TRANSPILER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TTranspiler Extends TVisitor

	Field ast:TASTNode
	Field TAB:String = "~t"
	
	Method New( ast:TASTNode, tab:String="~t" )
		Self.ast = ast
		Self.TAB = tab
	End Method
	
	' Create source code from the AST
	Method run:String()
'DebugStop
		Local text:String = visit( ast, "visit" )
		Return text
	End Method
	
	Method reveal:String()
	End Method
	
	Method header:String() Abstract

	' ABSTRACT METHODS

	Method visit_program:String( arg:TVisitorArg ) 'node:TASTCompound, indent:String="" )
'DebugStop
		Local text:String = header()
		text :+ visitChildren( arg.node, "visit", "" )
		Return text
	End Method

	Method visit_EOL:String( arg:TVisitorArg ) 'node:TASTNode, indent:String="" )
		Return "~n"
	End Method
	
End Type
